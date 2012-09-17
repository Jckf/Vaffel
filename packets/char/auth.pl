use warnings;

$server->register_handler(0x070B,sub {
	my ($handle,%packet) = @_;

	my ($user_id,$pass) = (readword(substr($packet{'args'},0,4)),substr($packet{'args'},4));

	my $query = $mdb->prepare("SELECT name FROM users WHERE id=? AND pass=?");
	$query->execute($user_id,$pass);

	if (!$query->rows) {
		# Invalid user or password.
		console(who($handle) . ' send invalid user ID or password!');
	} else {
		# Ok =)
		my $user = $query->fetchrow_hashref();
		$clients{$handle}{'user'} = $user_id;
		$clients{$handle}{'name'} = $user->{'name'};

		$server->send_packet($handle,$server->build_packet(0x070C,
			chr(0) .
			dword(0x87654321) .
			dword(0x00000000)
		));

		console(who($handle) . ' logged in.');
	}
});

return 1;
