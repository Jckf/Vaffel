use warnings;

$server->register_handler(0x079F,sub {
	my ($handle,%packet) = @_;

	my $client = readword(substr($packet{'args'},0,2));

	$server->send_packet($handle,$server->build_packet(0x079F,
		word($client) .
		word($world{$clients{$handle}{'map'}}{'players'}{$client}{'hp'}) .
		word(0)
	));
});

return 1;
