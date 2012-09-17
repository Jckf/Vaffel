use warnings;

$server->register_handler(0x0700,sub {
	my ($handle,%packet) = @_;

	$server->send_packet($handle,$server->build_packet(0x0700,
		word(0)
	));
});

return 1;
