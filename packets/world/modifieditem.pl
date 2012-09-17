use warnings;

$server->register_handler(0x07D8,sub {
	my ($handle,%packet) = @_;

	my %result = $server->build_packet(0x07D8,
		word($clients{$handle}{'id'}) .
		dword(readdword(substr($packet{'args'},0,4)))
	);

	for my $p (keys(%{$world{$clients{$handle}{'map'}}{'players'}})) {
		$server->send_packet($world{$clients{$handle}{'map'}}{'players'}{$p}{'handle'},%result);
	}
});

return 1;
