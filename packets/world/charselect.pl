use warnings;

$server->register_handler(0x071C,sub {
	my ($handle,%packet) = @_;

	$server->send_packet($handle,$server->build_packet(0x0707,
		chr(0x00)
	));
});

return 1;
