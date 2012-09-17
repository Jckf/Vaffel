use warnings;

$server->register_handler(0x0708,sub {
	my ($handle,%packet) = @_;

	my $username = substr($packet{'args'},32,-1);

	my $query = $mdb->prepare("SELECT id,pass,level,world FROM users WHERE name=?");
	$query->execute($username);

	my %reply;
	if (!$query->rows) {
		# Bad username.
		%reply = $server->build_packet(0x0708,chr(0x02) . dword(0x00000000));

		console(who($handle) . ' sent invalid username!');
	} else {
		my $user = $query->fetchrow_hashref();
		if ($user->{'pass'} ne substr($packet{'args'},0,32)) {
			# Bad password.
			%reply = $server->build_packet(0x0708,chr(0x03) . dword(0x00000000));

			console(who($handle) . ' sent invalid password for user ' . $username . '!');
		} elsif ($user->{'level'} < 0) {
			# Banned.
			%reply = $server->build_packet(0x0708,chr(0x05) . dword(0x00000000));

			console(who($handle) . ' requested login with banned user ' . $username . '!');
		} elsif ($user->{'level'} == 0) {
			# Not activated.
			%reply = $server->build_packet(0x0708,chr(0x09) . dword(0x00000000));

			console(who($handle) . ' requested login with inactive user ' . $username . '!');
		} elsif ($user->{'world'}) {
			# Already online.
			# TODO: Do something to kick the client from the world server.
			$query = $mdb->prepare("UPDATE users SET world=NULL WHERE id=?");
			$query->execute($user->{'id'});
			%reply = $server->build_packet(0x0708,chr(0x04) . dword(0x00000000));

			console(who($handle) . ' request login with in-game user ' . $username . '!');
		} else {
			# Okay =)
			$clients{$handle}{'user'} = $user->{'id'};
			$clients{$handle}{'name'} = $username;

			my $level = 0x0064;
			if ($user->{'level'} > 1) {
				$level = 0x0100 * $user->{'level'};
			}
			my $args = chr(0x00) . word($level) . word(0x0000);

			$query = $mdb->prepare("SELECT id,name FROM channels");
			$query->execute();
			while (my $channel = $query->fetchrow_hashref()) {
				$args .= $channel->{'id'} . $channel->{'name'} . chr(0x00) . chr($channel->{'id'}) . chr(0x00) . word(0x0000);
			}

			%reply = $server->build_packet(0x0708,$args);

			console(who($handle) . ' logged in.');
		}
	}

	$server->send_packet($handle,%reply);
});

return 1;
