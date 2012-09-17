#!/usr/bin/perl
use strict;
use warnings;
use Devel::SimpleTrace;
use Config::INI::Reader;
use DBI;
use DBD::mysql;
use lib './lib';
use DataUnits;
use Vaffel;

our ($listener,$select); # Socket stuff.
our (%clients,%world); # World stuff.
our ($last_tick); # Tick stuff.

our $config = Config::INI::Reader->read_file('config.ini');

require './subs/common.pl';
require './subs/world.pl';

console_prefix('WORLD') if $ENV{'vaffel_threads'};

console('Connecting to database' . ($config->{'MainDB'}->{'channel'} ? '' : 's') . '...');
our ($mdb,$cdb) = db_connect(1);

if (!$mdb || !$cdb) {
	console('Could not connect to database!');
	exit;
}

our $server = Vaffel->new(
	'bind_address'	=> $config->{'World'}->{'address'},
	'bind_port'		=> $config->{'World'}->{'port'},
	'first_command'	=> 0x070B,
	'dump'			=> 0 # Dump incoming packets to data directory.
);

$server->register_handler('start',\&event_start);
$server->register_handler('tick',\&event_tick);
$server->register_handler('connect',\&event_connect);
$server->register_handler('disconnect',\&event_disconnect);
$server->register_handler('unknown',\&event_unknown);

console('Loading packet handlers...');
for (<./packets/world/*.pl>) {
	my $filename = lc($_);
	$filename =~ s/.*\/(.+)\..+/$1/i;
	console('    ' . $filename);
	do $_;
	warn $@ if $@;
	warn $! if $!;
}

console('Loading STB files...');
our (%stb_cols,%stbs);
require './data/stb_cols.pl';
for (<./data/stb/*.STB>) {
	my $filename = lc($_);
	$filename =~ s/.*\/(.+)\..+/$1/i;
	console('    ' . $filename);
	%{$stbs{$filename}} = load_stb($_,@{$stb_cols{$filename}});
}

console('Loading chat commands...');
our %chat_commands;
for (<./commands/*.pl>) {
	my $filename = lc($_);
	$filename =~ s/.*\/(.+)\..+/$1/i;
	console('    ' . $filename);
	do $_;
	warn $@ if $@;
	warn $! if $!;
}

console('Loading NPCs...');
my $npc_count = 0;
my $npc_query = $mdb->prepare("SELECT id,type,map,dir,x,y,dialogid FROM npcs");
$npc_query->execute();
while (my $npc = $npc_query->fetchrow_hashref()) {
	$npc_count++;

	%{$world{$npc->{'map'}}{'npcs'}{client_id($npc->{'map'})}} = %{{
		'type'		=> $npc->{'type'},
		'direction'	=> $npc->{'dir'},
		'x'			=> $npc->{'x'} * 100,
		'y'			=> $npc->{'y'} * 100,
		'dialog'	=> $npc->{'dialogid'} || $npc->{'type'} - 900
	}}
}
console('    ' . $npc_count);

console('Loading mobs...');
my $mob_count = 0;
my $mob_query = $mdb->prepare("SELECT * FROM mobgroups WHERE isactive=1"); # Bad boy, using * =(
$mob_query->execute();
while (my $mob_group = $mob_query->fetchrow_hashref()) {
	my $group_count = 0;
	my ($mob,undef) = split(/\|/,$mob_group->{'moblist'},2);
	my ($id,$amount,$tactical) = split(/\,/,$mob,3);
	for (1..$amount) {
		$mob_count++;
		$group_count++;

		my ($x,$y) = rand_in_circle($mob_group->{'x'} * 100,$mob_group->{'y'} * 100,$mob_group->{'range'} * 100);

		my $client_id = client_id($mob_group->{'map'});

		my $hp = $stbs{'list_npc'}{$id}{'hp'};
		console('No HP info found for mob type ' . $id . '!') if !$hp;

		%{$world{$mob_group->{'map'}}{'mobs'}{$client_id}} = %{{
			'type'		=> $id,
			'range'		=> $mob_group->{'range'} * 100,
			'x_orig'	=> $mob_group->{'x'} * 100,
			'y_orig'	=> $mob_group->{'y'} * 100,
			'x'			=> $x,
			'y'			=> $y,
			'x_dest'	=> $x,
			'y_dest'	=> $y,
			'hp'		=> $hp,
			'last_move'	=> time()
		}};
		last if $group_count >= $mob_group->{'limit'};
	}
}
console('    ' . $mob_count);

console('Starting server...');
$server->run();
console('Server stopped!');

exit;

sub event_disconnect {
	my ($handle) = @_;

	if ($clients{$handle}{'map'}) {
		for (keys(%{$world{$clients{$handle}{'map'}}{'players'}})) {
			if ($clients{$handle}{'id'} != $_) {
				clear_map_client_from_player($world{$clients{$handle}{'map'}}{'players'}{$_}{'handle'},$clients{$handle}{'id'});
			}
		}

		# TODO: Remove ownership of drops.

		delete $world{$clients{$handle}{'map'}}{'players'}{$clients{$handle}{'id'}};
		delete $clients{$handle}{'map'};
		delete $clients{$handle}{'id'};
	}

	my $query = $mdb->prepare("UPDATE users SET world=NULL WHERE id=?");
	$query->execute($clients{$handle}{'user'}{'id'});

	console(who($handle) . ' disconnected. Time online: ' . (time() - $clients{$handle}{'connected'}) . ' seconds.');

	delete $clients{$handle};
	$select->remove($handle);
	$handle->close();
}

sub event_tick {
	return if $last_tick && $last_tick == time(); # Only tick once a second.
	$last_tick = time();

	if (!$mdb || !$cdb) {
		console('Lost database connection!');
		console('Reconnecting...');
		db_connect();
	}

	for my $map (keys(%world)) {
		next if scalar(keys(%{$world{$map}{'players'}})) <= 0; # Don't process maps withut players.

		my @move_mobs;
		for my $mob (keys(%{$world{$map}{'mobs'}})) {
			if (time() - $world{$map}{'mobs'}{$mob}{'last_move'} >= 8 + int(rand(5))) {
				($world{$map}{'mobs'}{$mob}{'x_dest'},$world{$map}{'mobs'}{$mob}{'y_dest'}) = (0,0);
				while (distance($world{$map}{'mobs'}{$mob}{'x_orig'},$world{$map}{'mobs'}{$mob}{'y_orig'},$world{$map}{'mobs'}{$mob}{'x_dest'},$world{$map}{'mobs'}{$mob}{'y_dest'}) > $world{$map}{'mobs'}{$mob}{'range'}) {
					($world{$map}{'mobs'}{$mob}{'x_dest'},$world{$map}{'mobs'}{$mob}{'y_dest'}) = rand_in_circle($world{$map}{'mobs'}{$mob}{'x'},$world{$map}{'mobs'}{$mob}{'y'},1000);
				}

				push(@move_mobs,$mob);

				$world{$map}{'mobs'}{$mob}{'last_move'} = time();
				# TODO: Calculate ETA and do the same check we do for players.
				$world{$map}{'mobs'}{$mob}{'x'} = $world{$map}{'mobs'}{$mob}{'x_dest'};
				$world{$map}{'mobs'}{$mob}{'y'} = $world{$map}{'mobs'}{$mob}{'y_dest'};
			}
		}

		my @clear_drops;
		for my $drop (keys(%{$world{$map}{'drops'}})) {
			if (time() - $world{$map}{'drops'}{$drop}{'time'} > 300) { # TODO: Make a config entry for this.
				push(@clear_drops,$drop);
				delete $world{$map}{'drops'}{$drop};
			}
		}

		for my $player (keys(%{$world{$map}{'players'}})) {
			for my $mob (@move_mobs) {
				move_monster($world{$map}{'players'}{$player}{'handle'},$mob);
			}

			for my $drop (@clear_drops) {
				clear_map_client_from_player($world{$map}{'players'}{$player}{'handle'},$drop);
			}

			if (
				($world{$map}{'players'}{$player}{'x'} != $world{$map}{'players'}{$player}{'x_dest'} || $world{$map}{'players'}{$player}{'y'} != $world{$map}{'players'}{$player}{'y_dest'}) &&
				($world{$map}{'players'}{$player}{'eta'} && time() - $world{$map}{'players'}{$player}{'last_move'} >= $world{$map}{'players'}{$player}{'eta'})
			) {
				$world{$map}{'players'}{$player}{'x'} = $world{$map}{'players'}{$player}{'x_dest'};
				$world{$map}{'players'}{$player}{'y'} = $world{$map}{'players'}{$player}{'y_dest'};
			}
		}
	}
}
