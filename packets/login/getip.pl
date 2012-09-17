use warnings;

$server->register_handler(0x070A,sub {
	my ($handle,%packet) = @_;

	if (!$clients{$handle}{'user'}) {
		console(who($handle) . ' is not authenticated!');
		event_disconnect($handle);
		return;
	}

	my ($channel,$world) = (readword(substr($packet{'args'},0,2)),ord(substr($packet{'args'},4,1)));

	my $query = $mdb->prepare("UPDATE users SET world=? WHERE id=?");
	$query->execute($world,$clients{$handle}{'user'});

	$query = $mdb->prepare("SELECT address,port FROM charservers WHERE channel=?");
	$query->execute($channel);
	if ($query->rows) {
		my $charserver = $query->fetchrow_hashref();
		$server->send_packet($handle,$server->build_packet(0x070A,
			chr(0x00) .
			dword($clients{$handle}{'user'}) .
			dword(0x87654321) .
			$charserver->{'address'} .
			chr(0x00) .
			word($charserver->{'port'})
		));
	} else {
		console(who($handle) . ' selected unknown channel ' . $channel . '!');
		event_disconnect($handle);
	}
});

return 1;
