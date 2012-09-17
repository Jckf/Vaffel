use warnings;

$chat_commands{'savespawn'} = sub {
	my ($handle) = @_;

	my $query = $cdb->prepare("UPDATE characters SET map=?,x=?,y=? WHERE id=?");
	$query->execute(
		$clients{$handle}{'map'},
		player($handle,'x'),
		player($handle,'y'),
		$world{$clients{$handle}{'map'}}{'players'}{$clients{$handle}{'id'}}{'id'}
	);
};

return 1;
