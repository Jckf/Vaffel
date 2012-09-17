use warnings;
use Term::ANSIColor;

BEGIN {
	if ($^O eq 'MSWin32') {
		require Win32::Console::ANSI;
	}
}

our $console_prefix = '';

sub console_prefix {
	$console_prefix = shift;
}
sub console {
	my ($msg) = @_;

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time());
	$year += 1900;

	print color 'bold green';
	#print $year . '/' . sprintf('%02s',$mon) . '/' . sprintf('%02s',$mday) . ' ';
	print sprintf('%02s',$hour) . ':' . sprintf('%02s',$min) . '.' . sprintf('%02s',$sec) . ' ';

	print color 'bold yellow';
	print ($console_prefix ? $console_prefix . ' ' : '');

	my $color = 'bold white';
	$color = 'bold red' if substr($msg,-1,1) eq '!';
	$color = 'reset' if substr($msg,0,1) eq ' ';

	print color $color;
	print $msg . "\n";
}

sub db_connect {
	my ($both,$main,$channel) = @_;

	$main = DBI->connect('dbi:mysql:' . $config->{'MainDB'}->{'database'} . ':' . $config->{'MainDB'}->{'host'},$config->{'MainDB'}->{'user'},$config->{'MainDB'}->{'pass'});
	if ($both && $config->{'ChannelDB'}->{'enabled'}) {
		$channel = DBI->connect('dbi:mysql:' . $config->{'ChannelDB'}->{'database'} . ':' . $config->{'ChannelDB'}->{'host'},$config->{'ChannelDB'}->{'user'},$config->{'ChannelDB'}->{'pass'});
	} else {
		$channel = \$main;
	}

	return ($main,$channel);
}

sub event_start {
	($listener,$select) = @_;
	console('Server started.');
}
sub event_connect {
	my ($handle) = @_;
	console(who($handle) . ' connected.');
	$clients{$handle}{'connected'} = int(time());
}
sub event_unknown {
	my ($handle,%packet) = @_;
	console(who($handle) . ' sent unknown command 0x' . dechex($packet{'command'},4) . '!');
}

sub humanize_packet {
	my (%packet) = @_;
	return(sprintf('%-3s',$packet{'length'}) . ' ' . '0x' . dechex($packet{'command'},4) . ' ' . $packet{'args'} . '<');
}

sub who {
	my ($handle) = @_;

	if (%world && defined($clients{$handle}{'map'})) { # Character in-game.
		return 'Character ' . $world{$clients{$handle}{'map'}}{'players'}{$clients{$handle}{'id'}}{'name'};
	}

	if (defined($clients{$handle}{'user'}{'name'})) { # New structure used by world. Authenticated user.
		return 'User ' . $clients{$handle}{'user'}{'name'};
	}

	if (defined($clients{$handle}{'name'})) { # Old structure used by login and char. Authenticated user.
		return 'User ' . $clients{$handle}{'name'};
	}

	return 'Client ' . fileno($handle); # Just a connection. Might not even be a ROSE client.
}

return 1;
