use warnings;

$server->register_handler(0x07A9,sub {
	my ($handle,%packet) = @_;

	my $stat = ord(substr($packet{'args'},0,1));

	my @stats = ('str','dex','int','con','cha','sen');

	my $need = player($handle,$stats[$stat]) / 5;

	if (player($handle,'stat_p') >= $need) {
		player($handle,$stats[$stat],player($handle,$stats[$stat]) + 1);

		my $query = $cdb->prepare("UPDATE characters SET `" . $stats[$stat] . "`=? WHERE id=?"); # Bad query building =(
		$query->execute(player($handle,$stats[$stat]),player($handle,'id'));

		$server->send_packet($handle,$server->build_packet(0x07A9,
			chr($stat) .
			word(player($handle,$stats[$stat]))
		));
	} else {
		console(who($handle) . ' tried to add stats, but doesn\'t have enough points!');
	}
});

return 1;
