use warnings;

$chat_commands{'cleardrops'} = sub {
	my ($handle,$map) = @_;

	$map = $clients{$handle}{'map'} if !$map;

	for my $d (keys(%{$world{$map}{'drops'}})) {
		for my $p (keys(%{$world{$map}{'players'}})) {
			clear_map_client_from_player($world{$map}{'players'}{$p}{'handle'},$d);
		}
		delete $world{$map}{'drops'}{$d};
	}
};

return 1;
