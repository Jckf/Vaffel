use warnings;

$chat_commands{'rename'} = sub {
	my ($handle,$old,$new) = @_;

	for my $c (keys(%{$world{$clients{$handle}{'map'}}{'players'}})) {
		if ($world{$clients{$handle}{'map'}}{'players'}{$c}{'name'} eq $old) {
			$world{$clients{$handle}{'map'}}{'players'}{$c}{'name'} = $new;
			my $query = $cdb->prepare("UPDATE characters SET name=? WHERE id=?");
			$query->execute($new,$world{$clients{$handle}{'map'}}{'players'}{$c}{'id'});
			teleport_player($world{$clients{$handle}{'map'}}{'players'}{$c}{'handle'},$clients{$handle}{'map'},$world{$clients{$handle}{'map'}}{'players'}{$c}{'x'},$world{$clients{$handle}{'map'}}{'players'}{$c}{'y'});
			last;
		}
	}
};

return 1;
