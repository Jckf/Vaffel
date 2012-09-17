use warnings;

$server->register_handler(0x0704,sub {
	my ($handle,%packet) = @_;

	if (!$clients{$handle}{'user'}) {
		console(who($handle) . ' is not authenticated!');
		return;
	}

	my $channel = ord(substr($packet{'args'},0,1));

	my $query = $mdb->prepare("SELECT id,name FROM worldservers WHERE channel=?");
	$query->execute($channel);

	my $args = dword($channel) . chr($query->rows);
	while (my $world = $query->fetchrow_hashref()) {
		$args .= word($world->{'id'}) . chr(0x00) . word(0x0000) . $world->{'name'} . chr(0x00);
	}

	$server->send_packet($handle,$server->build_packet(0x0704,$args));
});

return 1;
