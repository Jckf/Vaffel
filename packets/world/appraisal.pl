use warnings;

$server->register_handler(0x07BA,sub {
	my ($handle,%packet) = @_;

	my $slot = readword($packet{'args'},0,2);

	if (${player($handle,'items')}{$slot}) {
		$world{$clients{$handle}{'map'}}{'players'}{$clients{$handle}{'id'}}{'items'}{$slot}{'appraised'} = 1;

		my $query = $cdb->prepare("UPDATE inventory SET appraised=1 WHERE id=?");
		$query->execute($world{$clients{$handle}{'map'}}{'players'}{$clients{$handle}{'id'}}{'items'}{$slot}{'db_id'});

		$server->send_packet($handle,$server->build_packet(0x07BA,
			word($slot) .
			chr(0)
		));
	} else {
		console(who($handle) . ' tried appraising nothing!');
	}
});

return 1;
