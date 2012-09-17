use warnings;

$chat_commands{'fetch'} = sub {
	my ($handle,$who) = @_;

	if ($clients{$handle}{'user'}{'level'} < 2) {
		console(who($handle) . ' does not have access to the fetch command!');
		return;
	}

	for my $c (keys(%clients)) {
		if ($world{$clients{$c}{'map'}}{'players'}{$clients{$c}{'id'}}{'name'} eq $who) {
			teleport_player($world{$clients{$c}{'map'}}{'players'}{$clients{$c}{'id'}}{'handle'},$clients{$handle}{'map'},player($handle,'x'),player($handle,'y'));
			last;
		}
	}
};

return 1;
