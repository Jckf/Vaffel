use warnings;

$chat_commands{'dropzulie'} = sub {
	my ($handle,$amount,$spam,$range) = @_;

	$spam = 1 if !$spam || $spam < 1;
	$range = 150 if !$range;

	for (1..$spam) {
		my $drop_id = client_id($clients{$handle}{'map'});
		my ($x,$y) = rand_in_circle(player($handle,'x'),player($handle,'y'),$range);

		%{$world{$clients{$handle}{'map'}}{'drops'}{$drop_id}} = %{{
			'type'		=> 1,
			'amount'	=> $amount,
			'x'			=> $x,
			'y'			=> $y,
			'owner'		=> 0,
			'time'		=> time()
		}};

		for (keys(%{$world{$clients{$handle}{'map'}}{'players'}})) {
			spawn_drop_to_player($world{$clients{$handle}{'map'}}{'players'}{$_}{'handle'},$drop_id);
		}
	}
};

return 1;
