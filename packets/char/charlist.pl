use warnings;

$server->register_handler(0x0712,sub {
	my ($handle,%packet) = @_;

	if (!$clients{$handle}{'user'}) {
		console(who($handle) . ' is not authenticated!');
		return;
	}

	my $query = $cdb->prepare("SELECT id,name,level,sex,face,hair,job,deleted FROM characters WHERE user=?");
	$query->execute($clients{$handle}{'user'});

	$clients{$handle}{'charcount'} = $query->rows;
	my $args = chr($query->rows);

	while (my $char = $query->fetchrow_hashref()) {
		$args .=
			$char->{'name'} .
			chr(0x00) .
			chr($char->{'sex'}) .
			word($char->{'level'}) .
			word($char->{'job'}) .
			dword($char->{'deleted'}) .
			chr(0x00) .
			dword($char->{'face'}) .
			dword($char->{'hair'})
		;

		my $query = $cdb->prepare("SELECT item,slot,refined FROM inventory WHERE owner=? AND slot<10");
		$query->execute($char->{'id'});

		my %items;
		while (my $item = $query->fetchrow_hashref()) {
			$items{$item->{'slot'}}{'item'} = $item->{'item'};
			$items{$item->{'slot'}}{'refined'} = $item->{'refined'};
		}

		for (2,3,5,6,1,4,7,8) {
			if ($items{$_}) {
				$args .=
					word($items{$_}{'item'}) .
					word($items{$_}{'refined'})
				;
			} else {
				$args .= dword(0x00000000); # Nothing equipped in slot $_.
			}
		}
	}

	$server->send_packet($handle,$server->build_packet(0x0712,$args));
});

return 1;
