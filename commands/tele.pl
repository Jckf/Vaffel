use warnings;

$chat_commands{'tele'} = sub {
	my ($handle,$map,$x,$y) = @_;

	if ($clients{$handle}{'user'}{'level'} < 2) {
		console(who($handle) . ' does not have access to the tele command!');
		return;
	}

	teleport_player($handle,$map,$x * 100,$y * 100);
};

return 1;
