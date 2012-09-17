use warnings;

$server->register_handler(0x07A5,sub {
	my ($handle,%packet) = @_;

	# From and to are the opposite here of what they are in osRose.
	my ($to_slot,$from_slot) = (readword(substr($packet{'args'},0,2)),readword(substr($packet{'args'},2,2)));

	# Equipping and unequipping swaps from and to.
	if (!${player($handle,'items')}{$from_slot}) {
		my $tmp = $from_slot;
		$from_slot = $to_slot;
		$to_slot = $tmp;

		if (!${player($handle,'items')}{$from_slot}) {
			console(who($handle) . ' tried to equip nothing!');
			return;
		}
	}

	if ($to_slot == 0) {
		for (12..139) { # 139 is probably too high and includes consumables and materials?
			if (!${player($handle,'items')}{$_}) {
				$to_slot = $_;
				last;
			}
		}
	}

	# TODO: Check stats and level requirement.

	if ($from_slot == 7 || $to_slot == 7) {
		# TODO: Clear attack buffs on weapon change.
	} elsif ($from_slot == 8 || $to_slot == 8) {
		# TODO: Clear defence buffs on sheild change.
	}

	# Make the move.
	move_item($handle,$from_slot,$to_slot);

	# Did we take something from a visible slot?
	if ($from_slot < 10) {
		my $data = dword(0x00000000); # No data if we took something out of a slot.
		if (${player($handle,'items')}{$from_slot}) {
			$data =
				word(${player($handle,'items')}{$from_slot}{'id'}) .
				word(item_refine(%{${player($handle,'items')}{$from_slot}}))
			;
		}
		my %info = $server->build_packet(0x07A5,
			word($clients{$handle}{'id'}) .
			word($from_slot) .
			$data .
			word(player($handle,'mspeed'))
		);
		for (keys(%{$world{$clients{$handle}{'map'}}{'players'}})) {
			$server->send_packet($world{$clients{$handle}{'map'}}{'players'}{$_}{'handle'},%info);
		}
	}

	# Did we put something into a visible slot?
	if ($to_slot < 10) {
		my %info = $server->build_packet(0x07A5,
			word($clients{$handle}{'id'}) .
			word($to_slot) .
			word(${player($handle,'items')}{$to_slot}{'id'}) .
			word(item_refine(%{${player($handle,'items')}{$to_slot}})) .
			word(player($handle,'mspeed'))
		);
		for (keys(%{$world{$clients{$handle}{'map'}}{'players'}})) {
			$server->send_packet($world{$clients{$handle}{'map'}}{'players'}{$_}{'handle'},%info);
		}
	}

	# TODO: Check for two-handed weapon and possibly unequip shield.
});

return 1;
