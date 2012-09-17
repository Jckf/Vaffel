use warnings;

$chat_commands{'kill'} = sub {
	my ($handle,$who) = @_;

	if ($clients{$handle}{'user'}{'level'} < 2) {
		console(who($handle) . ' does not have access to the kill command!');
		return 1;
	}

	for my $type ('players','mobs') {
		for my $client (keys(%{$world{$clients{$handle}{'map'}}{$type}})) {
			if ($client == player($handle,'attacking') || ($who && $type eq 'players' && $world{$clients{$handle}{'map'}}{$type}{$client}{'name'} eq $who)) {
				announce(player($handle,'name') . ' killed someone with their god like powers!');
				$world{$clients{$handle}{'map'}}{$type}{$client}{'hp'} = 0;
				# TODO: Death animation.
				return;
			}
		}
	}
};

return 1;
