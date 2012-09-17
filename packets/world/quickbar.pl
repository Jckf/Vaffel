use warnings;

$server->register_handler(0x07AA,sub {
	my ($handle,%packet) = @_;

	my $slot = ord(substr($packet{'args'},0,1));
	my $item = readword(substr($packet{'args'},2,2));

	# TODO: Store it in DB.

	$server->send_packet($handle,$server->build_packet(0x07AA,
		chr($slot) .
		word($item)
	));
});

return 1;
