use warnings;

$chat_commands{'userlevel'} = sub {
	my ($handle,$who,$level) = @_;

	if ($clients{$handle}{'user'}{'level'} < 3) {
		console(who($handle) . ' does not have access to the userlevel command!');
		return;
	}

	for (keys(%clients)) {
		if ($clients{$_}{'user'}{'name'} eq $who) {
			console(who($handle) . ' changed ' . $who . '\'s access level to ' . $level . '!');
			$clients{$_}{'user'}{'level'} = $level;

			if (-2 < $level && $level < 4) {
				my $query = $mdb->prepare("UPDATE users SET level=? WHERE id=?");
				$query->execute($level,$clients{$handle}{'user'}{'id'});
			}

			last;
		}
	}
};

return 1;
