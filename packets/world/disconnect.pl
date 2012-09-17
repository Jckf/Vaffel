use warnings;

$server->register_handler(0x0707,sub {
	my ($handle,%packet) = @_;

	$server->send_packet($handle,$server->build_packet(0x0707,
		word(0)
	));

	event_disconnect($handle);
});

return 1;
