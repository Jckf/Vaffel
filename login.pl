#!/usr/bin/perl
use strict;
use warnings;
use Config::INI::Reader;
use DBI;
use DBD::mysql;
use lib './lib';
use DataUnits;
use Vaffel;

our ($listener,$select,$last_tick,%clients);

our $config = Config::INI::Reader->read_file('config.ini');

require './subs/common.pl';

console_prefix('LOGIN') if $ENV{'vaffel_threads'};

console('Connecting to database...');
our ($mdb) = db_connect(0);

if (!$mdb) {
	console('Could not connect to database!');
	exit;
}

our $server = Vaffel->new(
	'bind_address'	=> $config->{'Login'}->{'address'},
	'bind_port'		=> $config->{'Login'}->{'port'},
	'first_command'	=> 0x0703
);

$server->register_handler('start',\&event_start);
$server->register_handler('tick',\&event_tick);
$server->register_handler('connect',\&event_connect);
$server->register_handler('disconnect',\&event_disconnect);
$server->register_handler('unknown',\&event_unknown);

console('Loading packet handlers...');
for (<./packets/login/*.pl>) {
	my $filename = lc($_);
	$filename =~ s/.*\/(.+)\..+/$1/i;
	console('    ' . $filename);
	do $_;
	warn $@ if $@;
	warn $! if $!;
}

console('Starting server...');
$server->run();
console('Server stopped!');

exit;

sub event_disconnect {
	my ($handle) = @_;
	console(who($handle) . ' disconnected. Time online: ' . (int(time()) - $clients{$handle}{'connected'}) . ' seconds.');
	delete $clients{$handle};
}

sub event_tick {
	return if $last_tick && $last_tick == time(); # Only tick once a second.
	$last_tick = time();

	if (!$mdb) {
		console('Lost database connection!');
		console('Reconnecting...');
		db_connect();
	}
}
