use warnings;

$server->register_handler(0x0762,sub {
	my ($handle,%packet) = @_;

	my $weight = ord(substr($packet{'args'},0,1)) & 0xFF;

	# TODO: Store it in the character hash and use it to control stances.

	$server->send_packet($handle,$server->build_packet(0x0762,
		word($clients{$handle}{'id'}) .
		chr($weight)
	));
});

return 1;
