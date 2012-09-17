use warnings;

$server->register_handler(0x0715,sub {
	my ($handle,%packet) = @_;

	if (!$clients{$handle}{'user'}) {
		console(who($handle) . ' is not authenticated!');
		return;
	}

	my $char = substr($packet{'args'},3,-1);
	$clients{$handle}{'char'} = $char;

	my $query = $mdb->prepare("UPDATE users SET `char`=? WHERE id=?");
	$query->execute($char,$clients{$handle}{'user'});

	if ($query->rows) {
		$query = $mdb->prepare("SELECT world FROM users WHERE id=?");
		$query->execute($clients{$handle}{'user'});

		if ($query->rows) {
			my $user = $query->fetchrow_hashref();

			$query = $mdb->prepare("SELECT address,port FROM worldservers WHERE id=?");
			if ($query->execute($user->{'world'})) {
				my $world = $query->fetchrow_hashref();

				$server->send_packet($handle,$server->build_packet(0x0711,
					word($world->{'port'}) .
					dword($clients{$handle}{'user'}) .
					dword(0x87654321) .
					$world->{'address'} .
					chr(0x00)
				));
			} else {
				console(who($handle) . ' selected unknown world ' . $user->{'world'} . '!');
			}
		} else {
			console(who($handle) . ' has some problem in the database!');
		}
	} else {
		console(who($handle) . ' does not own character ' . $char . '!');
	}
});

return 1;
