use warnings;

$server->register_handler(0x0753,sub {
	my ($handle,%packet) = @_;

	if (!$clients{$handle}{'user'}{'id'}) {
		console(who($handle) . ' is not authenticated!');
		event_disconnect($handle);
		return;
	}

	if (player($handle,'spawned')) {
		console(who($handle) . ' tried spawning multiple times!');
		event_disconnect($handle);
		return;
	}
	player($handle,'spawned',1);

	$server->send_packet($handle,$server->build_packet(0x0753,
		word($clients{$handle}{'id'}) .
		word(player($handle,'hp')) .
		word(player($handle,'mp')) .
		dword(player($handle,'exp')) .
		dword(0) .
		word(0x0063) .
		chr(0x70) .
		chr(0x69) .
		chr(0x68) .
		chr(0x67) .
		word(0x0062) .
		chr(0x61) .
		chr(0x32) .
		chr(0x32) .
		chr(0x32) .
		chr(0x32) .
		chr(0x32) .
		chr(0x32) .
		chr(0x32) .
		chr(0x32) .
		chr(0x32) .
		chr(0x32) .
		chr(0x32) .
		word(0) . # PVP allowed?
		word(0) .
		dword(0) . # World time.
		word($clients{$handle}{'id'} + 0x0100) . # Type of PVP?
		word(0)
	));

	$server->send_packet($handle,$server->build_packet(0x0762,
		word($clients{$handle}{'id'}) .
		chr(0) # TODO: Weight. (Weight in a byte? o_O)
	));

	# Spawn client to other clients on same map, and show client all clients on that map.
	my %info = $server->build_packet(0x0782,
		word($clients{$handle}{'id'}) .
		chr(player($handle,'stance')) .
		word(player($handle,'mspeed'))
	);
	for (keys(%{$world{$clients{$handle}{'map'}}{'players'}})) {
		if ($_ ne $clients{$handle}{'id'}) {
			spawn_player_to_player($handle,$world{$clients{$handle}{'map'}}{'players'}{$_}{'handle'});
			spawn_player_to_player($world{$clients{$handle}{'map'}}{'players'}{$_}{'handle'},$handle);
		}
		$server->send_packet($world{$clients{$handle}{'map'}}{'players'}{$_}{'handle'},%info); # We're sending this to the client himself too. Don't know if we need that.
	}

	# Show client all NPCs on current map.
	for (keys(%{$world{$clients{$handle}{'map'}}{'npcs'}})) {
		spawn_npc_to_player($handle,$_);
	}

	# Show client all mobs on current map.
	for (keys(%{$world{$clients{$handle}{'map'}}{'mobs'}})) {
		spawn_monster_to_player($handle,$_);
	}

	# Show client all drops on current map.
	for (keys(%{$world{$clients{$handle}{'map'}}{'drops'}})) {
		spawn_drop_to_player($handle,$_);
	}
});

return 1;
