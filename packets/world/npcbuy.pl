use warnings;

$server->register_handler(0x07A1,sub {
	my ($handle,%packet) = @_;

	my ($npc,$buy_amount,$sell_amount) = (readword(substr($packets{'args'},0,2)),ord(substr($packets{'args'},2,1)),ord(substr($packets{'args'},3,1)));

	my $data =
		qword(player($handle,'zulie')) .
		chr(0x00)
	;

	for (0 .. $buy_amount - 1) {
		my ($tab,$item,$count) = (ord(substr($packet{'args'},8 + ($_ * 4),1)),ord(substr($packet{'args'},9 + ($_ * 4),1)),readword(substr($packet{'args'},10 + ($_ * 4),2)));

		# TODO: Alot of price magic.

		my $slot = 0;
		for (12..140) {
			if (!${player($handle,'items')}{$_}) {
				$slot = $_;
				last;
			}
		}

		# Not done yet. We need some STB data.
		# $stbs{'list_sell'}

		# $clients{$handle}{'inventory'}{$slot}{'item'} = $item;
		# $clients{$handle}{'inventory'}{$slot}{'type'} = $item->{'type'};
		# $clients{$handle}{'inventory'}{$slot}{'amount'} = $item->{'amount'};
		# $clients{$handle}{'inventory'}{$slot}{'durability'} = $item->{'durability'};
		# $clients{$handle}{'inventory'}{$slot}{'lifespan'} = $item->{'lifespan'};
		# $clients{$handle}{'inventory'}{$slot}{'appraised'} = $item->{'appraised'};
		# $clients{$handle}{'inventory'}{$slot}{'stats'} = $item->{'stats'};
		# $clients{$handle}{'inventory'}{$slot}{'refined'} = $item->{'refined'};
		# $clients{$handle}{'inventory'}{$slot}{'socket'} = $item->{'socket'};
		# $clients{$handle}{'inventory'}{$slot}{'gem'} = $item->{'gem'};

		# $data .=
			# chr($slot) .
			
		# ;
	}
});

return 1;
