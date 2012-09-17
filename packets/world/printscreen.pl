use warnings;

$server->register_handler(0x07EB,sub {
	my ($handle,%packet) = @_;

	$server->send_packet($handle,$server->build_packet(0x07EB,
		word($clients{$handle}{'user'}{'id'}) .
		word(0x0302) .
		word(0x2D17)
	));
});

return 1;
