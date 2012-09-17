use warnings;

$chat_commands{'mapinfo'} = sub {
	my ($handle,$map) = @_;

	$map = $clients{$handle}{'map'} if !$map;

	announce(
		$map . ': ' .
		'P:' . scalar(keys(%{$world{$map}{'players'}})) . ' ' .
		'M:' . scalar(keys(%{$world{$map}{'mobs'}})) . ' ' .
		'D:' . scalar(keys(%{$world{$map}{'drops'}})) . ' ' .
		'N:' . scalar(keys(%{$world{$map}{'npcs'}}))
	);
};

return 1;
