use warnings;

$server->register_handler(0x0756,sub {
	my ($handle,%packet) = @_;

	my $query = $cdb->prepare("UPDATE characters SET map=? WHERE id=?");
	$query->execute($clients{$handle}{'map'},player($handle,'id'));
});

return 1;
