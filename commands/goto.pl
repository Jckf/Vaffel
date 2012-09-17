use warnings;

$chat_commands{'goto'} = sub {
	my ($handle,$who) = @_;

	if ($clients{$handle}{'user'}{'level'} < 2) {
		console(who($handle) . ' does not have access to the goto command!');
		return;
	}

	for my $c (keys(%clients)) {
		if ($world{$clients{$c}{'map'}}{'players'}{$clients{$c}{'id'}}{'name'} eq $who) {
			teleport_player($handle,$clients{$c}{'map'},$world{$clients{$c}{'map'}}{'players'}{$clients{$c}{'id'}}{'x'},$world{$clients{$c}{'map'}}{'players'}{$clients{$c}{'id'}}{'y'});
			last;
		}
	}
};

return 1;
