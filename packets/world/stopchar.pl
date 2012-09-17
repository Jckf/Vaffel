use warnings;

$server->register_handler(0x0771,sub {
    my ($handle,%packet) = @_;

	if (!$clients{$handle}{'user'}{'id'}) {
		console(who($handle) . ' is not authenticated!');
		event_disconnect($handle);
		return;
	}

	player($handle,'x_dest',readfloat(substr($packet{'args'},0,4)));
	player($handle,'y_dest',readfloat(substr($packet{'args'},4,4)));
	player($handle,'eta',0); # We expect to arrive at our current position in 0 seconds =P

    my %stop = $server->build_packet(0x0770,
		word($clients{$handle}{'id'}) .
		float(player($handle,'x_dest')) .
		float(player($handle,'y_dest')) .
		word(readword(substr($packet{'args'},8,2)))
    );

	for (keys(%{$world{$clients{$handle}{'map'}}{'players'}})) {
		$server->send_packet($world{$clients{$handle}{'map'}}{'players'}{$_}{'handle'},%stop);
	}
});

return 1;
