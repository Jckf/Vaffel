#!/dev/null
use strict;
use warnings;
use Time::HiRes;
use IO::Socket::INET;
use IO::Select;

package Vaffel;

use DataUnits;

sub new {
	my ($class,%args) = @_;
	my $self = {};

	$self->{'handlers'} = {};
	$self->{'select'} = undef;
	$self->{'listener'} = undef;
	$self->{'current_reads'} = {};
	$self->{'encryption'} = {};
	$self->{'first_command'} = 0x0000;
	$self->{'dump'} = 0;

	for (keys(%args)) {
		$self->{$_} = $args{$_};
	}

	bless($self,$class);
	return $self;
}

sub register_handler {
	my ($self,$command,$handler) = @_;
	$self->{'handlers'}->{$command} = $handler;
}

sub run {
	my ($self) = @_;

	$self->{'listener'} = IO::Socket::INET->new(
		Listen		=> 5,
		LocalAddr	=> $self->{'bind_address'},
		LocalPort	=> $self->{'bind_port'},
		Proto		=> 'tcp'
	);

	$self->{'select'} = IO::Select->new($self->{'listener'});

	if (defined($self->{'handlers'}->{'start'})) {
		&{$self->{'handlers'}->{'start'}}($self->{'listener'},$self->{'select'});
	}

	while ($self->{'listener'}) {
		if (defined($self->{'handlers'}->{'tick'})) {
			&{$self->{'handlers'}->{'tick'}}();
		}

		my @can_read = $self->{'select'}->can_read(0);
		if (@can_read == 0) {
			Time::HiRes::sleep(0.01);
			next;
		}
		for my $handle (@can_read) {
			if ($handle eq $self->{'listener'}) {
				my $client = $handle->accept();
				$self->{'select'}->add($client);

				$self->{'current_reads'}->{$client}->{'reads'} = 0;
				$self->{'current_reads'}->{$client}->{'time'} = time();

				if (defined($self->{'handlers'}->{'connect'})) {
					&{$self->{'handlers'}->{'connect'}}($client);
				}
			} else {
				# Lag users who are spamming.
				if ($self->{'current_reads'}->{$handle}->{'time'} != time()) {
					$self->{'current_reads'}->{$handle}->{'reads'} = 0;
					$self->{'current_reads'}->{$handle}->{'time'} = time();
				} elsif ($self->{'current_reads'}->{$handle}->{'reads'} >= 8) {
					next; # TODO: Record how many "strikes" this user has and disconnecti if too many?
				}
				$self->{'current_reads'}->{$handle}->{'reads'}++;

				# Read length definition.
				my ($enc_packet,$enc_packet_more) = ('','');
				sysread($handle,$enc_packet,2);
				if (length($enc_packet) != 2) {
					# We tried to read 2 bytes, but got less (possibly nothing). Get rid of this client.
					if (defined($self->{'handlers'}->{'disconnect'})) {
						&{$self->{'handlers'}->{'disconnect'}}($handle);
					}
					$self->{'encryption'}->{$handle} = undef;
					$self->{'select'}->remove($handle);
					next;
				}
				# Read the rest of the packet.
				sysread($handle,$enc_packet_more,readword($enc_packet) - 2);
				$enc_packet .= $enc_packet_more;

				# Calibrate to this client's encryption.
				if (!defined($self->{'encryption'}->{$handle})) {
					for (0x00 .. 0xFF) {
						if (readword(chr(ord(substr($enc_packet,2,1)) ^ $_) . chr(ord(substr($enc_packet,3,1)) ^ $_)) == $self->{'first_command'}) {
							$self->{'encryption'}->{$handle} = $_;
							last;
						}
					}
				}
				if (!defined($self->{'encryption'}->{$handle})) {
					# Couldn't detect encryption. Possibly an old client.
					if (defined($self->{'handlers'}->{'disconnect'})) {
						&{$self->{'handlers'}->{'disconnect'}}($handle);
					}
					$self->{'encryption'}->{$handle} = undef;
					$self->{'select'}->remove($handle);
					next;
				}

				# Decode the packet.
				my $raw_packet = substr($enc_packet,0,2);
				for (split(//,substr($enc_packet,2,-2))) {
					$raw_packet .= chr(ord($_) ^ $self->{'encryption'}->{$handle});
				}
				$raw_packet .= substr($enc_packet,-2);

				# Build a packet hash manually.
				my %packet;
				$packet{'length'} = hex('0x' . dechex(ord(substr($raw_packet,1,1))) . dechex(ord(substr($raw_packet,0,1))));
				$packet{'command'} = hex('0x' . dechex(ord(substr($raw_packet,3,1))) . dechex(ord(substr($raw_packet,2,1))));
				$packet{'junk'} = hex('0x' . dechex(ord(substr($raw_packet,5,1))) . dechex(ord(substr($raw_packet,4,1))));
				$packet{'args'} = '';
				if (length($raw_packet) > 6) {
					$packet{'args'} = substr($raw_packet,6);
				}

				if ($self->{'dump'}) {
					open(my $fh,'>./data/0x' . dechex($packet{'command'},4) . '.log');
					print $fh ($raw_packet);
					close($fh);
				}

				if (defined($self->{'handlers'}->{'read'})) {
					&{$self->{'handlers'}->{'read'}}($handle,%packet);
				}

				# Handle it if we can.
				if (defined($self->{'handlers'}->{$packet{'command'}})) {
					&{$self->{'handlers'}->{$packet{'command'}}}($handle,%packet);
				} else {
					if (defined($self->{'handlers'}->{'unknown'})) {
						&{$self->{'handlers'}->{'unknown'}}($handle,%packet);
					}
				}
			}
		}
	}
}

sub halt {
	my ($self) = @_;

	$self->{'listener'} = undef;
}

sub fakelag_decrease {
	my ($self,$handle) = @_;

	$self->{'current_reads'}->{$handle}->{'reads'}--;
}

sub build_packet {
	my ($self,$command,$args) = @_;

	my %packet;
	$packet{'length'} = 6;
	$packet{'command'} = $command;
	$packet{'junk'} = 0x2604;
	$packet{'args'} = '';
	if (defined($args)) {
		$packet{'length'} += length($args);
		$packet{'args'} = $args;
	}

	return %packet;
}

sub send_packet {
	my ($self,$handle,%packet) = @_;

	if (defined($self->{'handlers'}->{'write'})) {
		&{$self->{'handlers'}->{'write'}}($handle,%packet);
	}

	# Send packet. Trunkate it to avoid breakage if it is retarded.
	syswrite($handle,word($packet{'length'}) . word($packet{'command'}) . word($packet{'junk'}) . $packet{'args'},$packet{'length'});
}

return 1;
