use warnings;

$server->register_handler(0x0703,sub {
	my ($handle,$packet) = @_;

	$server->send_packet($handle,$server->build_packet(0x07FF,
		word(0xAF02) .
		word(0xBD46) .
		word(0x0009) .
		word(0x0012) .
		chr(0x00) .
		dword(0xCDCDCDCD) .
		dword(0xCDCDCDCD) .
		dword(0xCDCDCDCD) .
		dword(0xCDCDCDCD) .
		word(0xCDCD) .
		chr(0xD3)
	));
});

return 1;
