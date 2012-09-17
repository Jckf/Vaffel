use warnings;

$chat_commands{'telemove'} = sub {
	my ($handle,@args) = @_;

	if ($clients{$handle}{'user'}{'level'} < 2) {
		console(who($handle) . ' does not have access to the telemove command!');
		return;
	}

	$clients{$handle}{'movesub'} = sub {
		teleport_player($_[0],$clients{$_[0]}{'map'},$_[1],$_[2]);
	}
};

return 1;
