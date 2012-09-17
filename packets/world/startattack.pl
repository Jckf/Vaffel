use warnings;

$server->register_handler(0x0798,sub {
	my ($handle,%packet) = @_;

	my $target = readword(substr($packet{'args'},0,2));

	if (!mob($handle,$target,'hp')) { # Just read something to see if it's a valid mob.
		console(who($handle) . ' attacked an invalid monster!');
		event_disconnect($handle);
		return;
	}

	player($handle,'x_dest',mob($handle,$target,'x'));
	player($handle,'y_dest',mob($handle,$target,'y'));
	player($handle,'attacking',$target);

	$server->send_packet($handle,$server->build_packet(0x079F,
		word($target) .
		dword(mob($handle,$target,'hp'))
	));

	# TODO: There are different types of attack. Handle only normal attacks for now.

	my %attack = $server->build_packet(0x0798,
		word($clients{$handle}{'id'}) .
		word($target) .
		word(player($handle,'mspeed')) .
		float(mob($handle,$target,'x')) .
		float(mob($handle,$target,'y'))
	);

	my %players = &map($handle,'players');
	for (keys(%players)) {
		$server->send_packet($players{$_}{'handle'},%attack);
	}
});

return 1;
