use warnings; 

$server->register_handler(0x0785,sub {
	my ($handle,%packet) = @_;

	if (!$clients{$handle}{'user'}{'id'}) {
		console(who($handle) . ' is not authenticated!');
		event_disconnect($handle);
		return;
	}

	my $chatter = substr($packet{'args'},0,-1);

	my %shout = $server->build_packet(0x0785,
		player($handle,'name') .
		chr(0x00) .
		$chatter .
		chr(0x00)
	);

	my %players = &map($handle,'players');
	for (keys(%players)) {
		$server->send_packet($players{$_}{'handle'},%shout);
	}
});

return 1;
