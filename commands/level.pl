use warnings;

$chat_commands{'level'} = sub {
	my ($handle,$level) = @_;

	player($handle,'level',$level);
	player($handle,'stat_p',($level - 1) * 10);
	player($handle,'skill_p',($level - 1) * 3);

	my $query = $cdb->prepare("UPDATE characters SET level=? WHERE id=?");
	$query->execute($level,$world{$clients{$handle}{'map'}}{'players'}{$clients{$handle}{'id'}}{'id'});

	$server->send_packet($handle,$server->build_packet(0x079E,
		word($clients{$handle}{'id'}) .
		word(player($handle,'level')) .
		dword(player($handle,'exp')) .
		word(player($handle,'stat_p')) .
		word(player($handle,'skill_p'))
	));

	my %up = $server->build_packet(0x079E,
		word($clients{$handle}{'id'})
	);

	for (keys(%{$world{$clients{$handle}{'map'}}{'players'}})) {
		$server->send_packet($world{$clients{$handle}{'map'}}{'players'}{$_}{'handle'},%up)
	}
};

return 1;
