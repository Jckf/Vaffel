use warnings;

$server->register_handler(0x0714,sub {
	my ($handle,%packet) = @_;

	if (!$clients{$handle}{'user'}) {
		console(who($handle) . ' is not authenticated!');
		return;
	}

	my ($query,$deleted,$name) = (undef,0,substr($packet{'args'},2,-1));

	if (ord(substr($packet{'args'},1,1))) {
		# Delete.
		$deleted = int(time()) + $config->{'Char'}->{'delete_timeout'};
		$query = $cdb->prepare("UPDATE characters SET deleted=? WHERE user=? AND name=?");
		$query->execute($deleted,$clients{$handle}{'user'},$name);

		# Hard delete for testing.
		#$query = $cdb->prepare("DELETE FROM characters WHERE user=? AND name=?");
		#$query->execute($clients{$handle}{'user'},$name);
	} else {
		# Resurrect.
		$query = $cdb->prepare("UPDATE characters SET deleted=0 WHERE user=? AND name=?");
		$query->execute($clients{$handle}{'user'},$name);
	}

	if ($query->rows) {
		$server->send_packet($handle,$server->build_packet(0x0714,dword($deleted) . $name . chr(0x00)));
	}
});

return 1;
