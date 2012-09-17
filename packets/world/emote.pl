use warnings;

$server->register_handler(0x0781,sub {
	my ($handle,%packet) = @_;

	my %emote = $server->build_packet(0x0781,
		word(readword(substr($packet{'args'},0,2))) .
		word(readword(substr($packet{'args'},2,2))) .
		word($clients{$handle}{'id'})
	);

	for my $p (keys(%{$world{$clients{$handle}{'map'}}{'players'}})) {
		$server->send_packet($world{$clients{$handle}{'map'}}{'players'}{$_}{'handle'},%emote);
	}
});

return 1;
