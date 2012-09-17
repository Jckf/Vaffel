use warnings;

$server->register_handler(0x07DA,sub {
	my ($handle,%packet) = @_;

	my $action = ord(substr($packet{'args'},0,1));
	my $zulie = readqword(substr($packet{'args'},0,8));

	if ($action == 0x10) {
		if (player($handle,'zulie') < $zulie) {
			console(who($handle) . ' tried to deposit more zulie than he has!');
			event_disconnect($handle);
			return;
		}

		player($handle,'zulie',player($handle,'zulie') - $zulie);
		player($handle,'zulie_storage',player($handle,'zulie_storage') + $zulie);
	} elsif ($action == 0x11) {
		if (player($handle,'zulie_storage') < $zulie) {
			console(who($handle) . ' tried to withdraw more zulie than he has!');
			event_disconnect($handle);
			return;
		}

		player($handle,'zulie',player($handle,'zulie') + $zulie);
		player($handle,'zulie_storage',player($handle,'zulie_storage') - $zulie);
	}

	my $query = $cdb->prepare("UPDATE characters SET zulie=?,zulie_storage=? WHERE id=?");
	$query->execute(player($handle,'zulie'),player($handle,'zulie_storage'),player($handle,'id'));

	$server->send_packet($handle,$server->build_packet(0x07DA,
		qword(player($handle,'zulie')) .
		qword(player($handle,'zulie_storage'))
	));
});

return 1;
