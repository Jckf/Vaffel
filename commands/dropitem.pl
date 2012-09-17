use warnings;

$chat_commands{'dropitem'} = sub {
	my ($handle,$id,$type,$amount,$durability,$lifespan,$appraised,$stats,$refined,$socket,$gem,$loop,$range) = @_;

	for (1..($loop || 1)) {
		my $drop_id = client_id($clients{$handle}{'map'});
		my ($x,$y) = rand_in_circle(player($handle,'x'),player($handle,'y'),($range || 150));

		%{$world{$clients{$handle}{'map'}}{'drops'}{$drop_id}} = %{{
			'x'				=> $x,
			'y'				=> $y,
			'owner'			=> 0,
			'time'			=> time(),
			'id'			=> $id,
			'type'			=> $type,
			'amount'		=> $amount || 1,
			'durability'	=> $durability || 40,
			'lifespan'		=> $lifespan || 100,
			'appraised'		=> $appraised || 0,
			'stats'			=> $stats || 0,
			'refined'		=> $refined || 0,
			'socket'		=> $socket || 0,
			'gem'			=> $gem || 0
		}};

		for (keys(%{$world{$clients{$handle}{'map'}}{'players'}})) {
			spawn_drop_to_player($world{$clients{$handle}{'map'}}{'players'}{$_}{'handle'},$drop_id);
		}
	}
};

return 1;
