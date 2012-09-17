use warnings;

$server->register_handler(0x07A4,sub {
	my ($handle,%packet) = @_;

	my ($slot,$amount) = (ord(substr($packet{'args'},0,1)),readdword(substr($packet{'args'},1,4)));

	my $drop_id = client_id($clients{$handle}{'map'});
	my ($x,$y) = rand_in_circle(player($handle,'x'),player($handle,'y'),150);

	if ($slot == 0) {
		# Zulie.
		if ($amount <= 0 || $amount > player($handle,'zulie')) {
			console(who($handle) . ' tried to drop invalid amount of zulie!');
			event_disconnect($handle);
			return;
		}

		$world{$clients{$handle}{'map'}}{'drops'}{$drop_id}{'type'} = 1; # TODO: %{{}}
		$world{$clients{$handle}{'map'}}{'drops'}{$drop_id}{'amount'} = $amount;
		$world{$clients{$handle}{'map'}}{'drops'}{$drop_id}{'x'} = $x;
		$world{$clients{$handle}{'map'}}{'drops'}{$drop_id}{'y'} = $y;
		$world{$clients{$handle}{'map'}}{'drops'}{$drop_id}{'owner'} = 0;
		$world{$clients{$handle}{'map'}}{'drops'}{$drop_id}{'time'} = time();

		player($handle,'zulie',player($handle,'zulie') - $amount);
		my $query = $cdb->prepare("UPDATE characters SET zulie=? WHERE id=?");
		$query->execute(player($handle,'zulie'),player($handle,'id'));

		$server->send_packet($handle,$server->build_packet(0x071D,
			qword(player($handle,'zulie'))
		));
	} else {
		# Item.
		if (${player($handle,'items')}{$slot}{'amount'} < $amount) {
			console(who($handle) . ' tried to drop more items than he has!');
			#event_disconnect($handle);
			return;
		}

		%{$world{$clients{$handle}{'map'}}{'drops'}{$drop_id}} = %{{
			'type'		=> 2,
			'amount'	=> $amount,
			'x'			=> $x,
			'y'			=> $y,
			'owner'		=> 0,
			'time'		=> time()
		}};

		# Lazy way of popluating with item data =P
		for (keys(%{$world{$clients{$handle}{'map'}}{'players'}{$clients{$handle}{'id'}}{'items'}{$slot}})) {
			$world{$clients{$handle}{'map'}}{'drops'}{$drop_id}{$_} = $world{$clients{$handle}{'map'}}{'players'}{$clients{$handle}{'id'}}{'items'}{$slot}{$_};
		}

		# TODO: Maybe we have a stackable item? Then just remove $amount from it and leave the rest in the inventory.

		move_item($handle,$slot,0); # Moving to 0 deletes the item from inventory.
	}

	for (keys(%{$world{$clients{$handle}{'map'}}{'players'}})) {
		spawn_drop_to_player($world{$clients{$handle}{'map'}}{'players'}{$_}{'handle'},$drop_id);
	}
});

return 1;
