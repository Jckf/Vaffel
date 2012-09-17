use warnings;

sub distance {
	my ($x1,$y1,$x2,$y2) = @_;

	my $dx = $x1 - $x2;
	my $dy = $y1 - $y2;

	return sqrt(($dx * $dx) + ($dy * $dy));
}

sub item_head {
	my (%item) = @_;
	return (($item{'id'} & 0x7FFFFFFF) << 5) | ($item{'type'} & 0x1F);
}
sub item_body {
	my (%item) = @_;

	if ($item{'type'} >= 10 && $item{'type'} <= 13) {
		return $item{'amount'};
	}

	my $part1 = ($item{'refined'} >> 4) << 28;
	my $part2 = ($item{'appraised'} ? 1 : 0) << 27;
	my $part3 = ($item{'socketed'} ? 1 : 0) << 26;
	my $part4 = ($item{'lifespan'} * 10) << 16; # TODO: Special value for cart.
	my $part5 = $item{'durability'} << 9;
	my $part6 = $item{'stats'};
	my $part7 = $item{'gem'};

	return $part1 | $part2 | $part3 | $part4 | $part5 | $part6 | $part7;
}
sub item_refine {
	my (%item) = @_;

	my $data = $item{'refined'} * 256;
	if ($item{'gem'}) {
		$data += 0x0D00 + ($item{'gem'} - 320) * 4;
	}

	return $data;
}

sub load_stb {
	my ($file,@cols) = @_;

	my %data;

	open(my $fh,'<',$file);

	seek($fh,4,0);
	read($fh,my $data_offset,4);
	read($fh,my $row_count,4);
	read($fh,my $col_count,4);

	seek($fh,unpack('L',$data_offset),0);

	for my $row (0..unpack('L',$row_count) - 2) {
		for my $col (0..unpack('L',$col_count) - 2) {
			read($fh,my $cell_size,2);
			read($fh,$data{$row}{$cols[$col] || $col},unpack('S',$cell_size));
		}
	}

	close($fh);

	return %data;
}

sub client_id {
	my ($map) = @_;

	my ($id,@tested);
	while (
		!$id ||
		defined($world{$map}{'players'}{$id}) ||
		defined($world{$map}{'mobs'}{$id}) ||
		defined($world{$map}{'drops'}{$id}) ||
		defined($world{$map}{'npcs'}{$id})
	) {
		$id = 1 + int(rand(65535));
		$tested[$id] = 1;
		if (@tested > 65535) {
			console('OUT OF CLIENT ID\'S FOR MAP ' . $map . '! Tested ' . @tested . '!');
			last;
		}
	}

	return $id;
}

sub spawn_player_to_player {
	my ($handle,$player) = @_; # $handle is the client that we're spawning $player to. Both are socket handles.

	if (!player($handle,'spawned') || !player($player,'spawned')) {
		# One of these haven't spawned yet, so don't start messing with things.
		# It'll mess it up when he actually does spawn.
		return;
	}

	my $action = word(1) . word(0);
	if (player($player,'stance') <= 1) {
		# Sitting.
		$action = word(0x000A) . word(0);
	} elsif (player($player,'hp') <= 0) {
		# Dead.
		$action = word(3) . word(0);
	} elsif (player($player,'x') != player($player,'x_dest') || player($player,'y') != player($player,'y_dest')) {
		# Moving.
		$action = word(1) . word(player($player,'target'));
	} elsif (player($player,'attacking')) {
		# Attacking something.
		$action = word(2) . word(player($player,'attacking'));
	}

	my $stance = 0x0B;
	if (player($player,'stance') == 2) {
		$stance = 0;
	} elsif (player($player,'stance') == 3) {
		$stance = 1;
	} elsif (player($player,'stance') == 4) {
		$stance = 2;
	}

	my $equipment = '';
	for (2,3,5,6,1,4,7,8) {
		if (${player($player,'items')}{$_}) {
			$equipment .=
				word(${player($player,'items')}{$_}{'id'}) .
				word(${player($player,'items')}{$_}{'refined'})
			;
		} else {
			$equipment .= dword(0); # Nothing equipped to slot $_.
		}
	}
	$server->send_packet($handle,$server->build_packet(0x0793,
		word($clients{$player}{'id'}) .
		float(player($player,'x')) .
		float(player($player,'y')) .
		float(player($player,'x_dest')) .
		float(player($player,'y_dest')) .
		$action .
		chr($stance) .
		dword(0) .
		dword($clients{$player}{'id'} + 0x0100) . # Type of PVP?
		dword(0) . # Buffs.
		chr(player($player,'sex')) .
		word(player($player,'mspeed')) . # Move speed.
		word(0) .
		chr(1) .
		dword(player($player,'face')) .
		dword(player($player,'hair')) .
		$equipment . # Character equip.
		(word(0) x 3) . # Ammo.
		word(player($player,'job')) .
		chr(0) . # player($player,'level')
		(word(0) x 10) . # Cart.
		word(player($player,'hp') <= 0 ? 0 : 0xEA7B) .
		chr(0) . # Invisibility.
		word(0) .
		chr(0) . # Fairy.
		player($player,'name') .
		chr(0) .
		# <- Clan and buff things here (if in clan and has buffs that is).
		word(0)
	));

	# Send a 0x07D5 here if players are in the same party.

	# Send a 0x0796 here if the players are in the same cart.
}

sub spawn_npc_to_player {
	my ($handle,$npc) = @_;

	$server->send_packet($handle,$server->build_packet(0x0791,
		word($npc) .
		float($world{$clients{$handle}{'map'}}{'npcs'}{$npc}{'x'}) .
		float($world{$clients{$handle}{'map'}}{'npcs'}{$npc}{'y'}) .
		float($world{$clients{$handle}{'map'}}{'npcs'}{$npc}{'x'}) .
		float($world{$clients{$handle}{'map'}}{'npcs'}{$npc}{'y'}) .
		chr(0) .
		dword(0) .
		word(0x03E8) .
		word(0) .
		word(1) .
		(word(0) x 3) . # Buffs.
		word($world{$clients{$handle}{'map'}}{'npcs'}{$npc}{'type'}) .
		word($world{$clients{$handle}{'map'}}{'npcs'}{$npc}{'dialog'}) .
		float($world{$clients{$handle}{'map'}}{'npcs'}{$npc}{'direction'})
		# <- Special event NPC data here.
	));
}

sub spawn_drop_to_player {
	my ($handle,$drop) = @_;

	my $data;
	if ($world{$clients{$handle}{'map'}}{'drops'}{$drop}{'type'} == 1) {
		# Zulie.
		$data =
			dword(0xCCCCCCDF) .
			dword($world{$clients{$handle}{'map'}}{'drops'}{$drop}{'amount'}) .
			dword(0xCCCCCCCC) .
			word(0xCCCC)
		;
	} else {
		# Item.
		$data =
			dword(item_head(%{$world{$clients{$handle}{'map'}}{'drops'}{$drop}})) .
			dword(item_body(%{$world{$clients{$handle}{'map'}}{'drops'}{$drop}})) .
			dword(0) .
			word(0) .
			word($drop) .
			word(drop($handle,$drop,'owner')) .
			word(0x5F90)
		;
	}

	$server->send_packet($handle,$server->build_packet(0x07A6,
		float($world{$clients{$handle}{'map'}}{'drops'}{$drop}{'x'}) .
		float($world{$clients{$handle}{'map'}}{'drops'}{$drop}{'y'}) .
		$data .
		word($drop) .
		word($world{$clients{$handle}{'map'}}{'drops'}{$drop}{'owner'}) .
		word(0x5F90)
	));
}

sub spawn_monster_to_player {
	my ($handle,$mob) = @_;

	my $action = dword(0); # TODO.

	$server->send_packet($handle,$server->build_packet(0x0792,
		word($mob) .
		float(mob($handle,$mob,'x')) .
		float(mob($handle,$mob,'y')) .
		float(mob($handle,$mob,'x_dest')) .
		float(mob($handle,$mob,'y_dest')) .
		$action .
		chr(0) . # TODO: Is this a summon?
		dword(mob($handle,$mob,'hp')) .
		dword(0x64) . # TODO: Friendly 0 or hostile 0x64? (or group thingy?)
		dword(0) . # TODO: Buffs.
		word(mob($handle,$mob,'type')) .
		word(0)
		# <- TODO: Summon ownership info here.
	));
}

sub clear_map_client_from_player {
	my ($handle,$id) = @_;

	$server->send_packet($handle,$server->build_packet(0x0794,
		word($id)
	));
}

sub teleport_player {
	my ($handle,$map,$x,$y) = @_;

	for (keys(%{$world{$clients{$handle}{'map'}}{'players'}})) {
		if ($_ != $clients{$handle}{'id'}) {
			clear_map_client_from_player($world{$clients{$handle}{'map'}}{'players'}{$_}{'handle'},$clients{$handle}{'id'});
		}
	}
	player($handle,'spawned',0);

	my $cid = client_id($map); # Client ID on new map.
	%{$world{$map}{'players'}{$cid}} = %{$world{$clients{$handle}{'map'}}{'players'}{$clients{$handle}{'id'}}}; # Copy character data from old map to new.
	delete $world{$clients{$handle}{'map'}}{'players'}{$clients{$handle}{'id'}}; # Delete character data from old map.

	$clients{$handle}{'map'} = $map;
	$clients{$handle}{'id'} = $cid;

	player($handle,'x',$x);
	player($handle,'y',$y);
	player($handle,'x_dest',$x);
	player($handle,'y_dest',$y);

	$server->send_packet($handle,$server->build_packet(0x07A8,
		word($clients{$handle}{'id'}) .
		word($clients{$handle}{'map'}) .
		float(player($handle,'x')) .
		float(player($handle,'y')) .
		word(player($handle,'stance') == 4 ? 0x0201 : 1) . # Riding cart?
		(dword(0) x 3) .
		word(player($handle,'mspeed')) .
		(dword(0) x 9) .
		word(0)
	));

	# There is also some magic for carts that needs to be done here.
}

sub player {
	my ($handle,$field,$value) = @_;

	if (defined($value)) {
		$world{$clients{$handle}{'map'}}{'players'}{$clients{$handle}{'id'}}{$field} = $value;
	}

	if (defined($world{$clients{$handle}{'map'}}{'players'}{$clients{$handle}{'id'}})) {
		return $world{$clients{$handle}{'map'}}{'players'}{$clients{$handle}{'id'}}{$field};
	}
}

sub drop {
	my ($handle,$drop,$field,$value) = @_;

	if (defined($value)) {
		$world{$clients{$handle}{'map'}}{'drops'}{$drop}{$field} = $value;
	}

	if (defined($world{$clients{$handle}{'map'}}{'drops'}{$drop})) {
		return $world{$clients{$handle}{'map'}}{'drops'}{$drop}{$field};
	}
}

sub mob {
	my ($handle,$mob,$field,$value) = @_;

	if (defined($value)) {
		$world{$clients{$handle}{'map'}}{'mobs'}{$mob}{$field} = $value;
	}

	if (defined($world{$clients{$handle}{'map'}}{'mobs'}{$mob})) {
		return $world{$clients{$handle}{'map'}}{'mobs'}{$mob}{$field};
	}
}

sub map {
	my ($handle,$list) = @_;

	return %{$world{$clients{$handle}{'map'}}{$list}};
}

sub move_item {
	my ($handle,$from_slot,$to_slot) = @_;

	# Take the item out of $from_slot.
	my %item = %{${player($handle,'items')}{$from_slot}};
	delete $world{$clients{$handle}{'map'}}{'players'}{$clients{$handle}{'id'}}{'items'}{$from_slot};

	# Should we move it to another slot?
	if ($to_slot) {
		my $query = $cdb->prepare("UPDATE inventory SET slot=? WHERE id=?");

		# Is there something in the new slot already?
		if (${player($handle,'items')}{$to_slot}) {
			%{$world{$clients{$handle}{'map'}}{'players'}{$clients{$handle}{'id'}}{'items'}{$from_slot}} = %{${player($handle,'items')}{$to_slot}};
			$query->execute($from_slot,${player($handle,'items')}{$to_slot}{'db_id'});
		}

		# Does the item exist in the DB already?
		if ($from_slot) {
			$query->execute($to_slot,$item{'db_id'});
		} else {
			# Nope. Insert it.
			my $query = $cdb->prepare("INSERT INTO inventory (owner,slot,item,type,amount,durability,lifespan,appraised,stats,refined,socket,gem) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)");
			$query->execute(
				$world{$clients{$handle}{'map'}}{'players'}{$clients{$handle}{'id'}}{'id'},
				$to_slot,
				$item{'id'},
				$item{'type'},
				$item{'amount'},
				$item{'durability'},
				$item{'lifespan'},
				$item{'appraised'},
				$item{'stats'},
				$item{'refined'},
				$item{'socket'},
				$item{'gem'}
			);
			$item{'db_id'} = $cdb->last_insert_id(undef,undef,undef,undef);
		}

		%{$world{$clients{$handle}{'map'}}{'players'}{$clients{$handle}{'id'}}{'items'}{$to_slot}} = %item;
	} else {
		# Move it to the void.
		my $query = $cdb->prepare("DELETE FROM inventory WHERE id=?");
		$query->execute($item{'db_id'});
	}

	# Tell the client about the changes.
	my $data = '';
	for ($from_slot,$to_slot) {
		if ($_) {
			$data .= chr($_);
			if (${player($handle,'items')}{$_}) {
				$data .=
					dword(item_head(%{${player($handle,'items')}{$_}})) .
					dword(item_body(%{${player($handle,'items')}{$_}}))
				;
			} else {
				$data .= qword(0);
			}
			$data .=
				dword(0) .
				word(0)
			;
		}
	}
	$server->send_packet($handle,$server->build_packet(0x0718,
		chr($from_slot && $to_slot ? 0x02 : 0x01) .
		$data
	));
}

sub move_monster {
	my ($handle,$mob) = @_;

	$server->send_packet($handle,$server->build_packet(0x0797,
		word($mob) .
		word(0) .
		word(300) . # TODO: Mspeed?
		float(mob($handle,$mob,'x_dest')) .
		float(mob($handle,$mob,'y_dest')) .
		word(0xCDCD) .
		chr(1) # Stance.
	));
}

sub rand_in_circle {
	my $angle = rand(100) * (3.1415926535 * 2) / 100;
	my $dist = sqrt(rand(100) / 100) * $_[2];
	my $x = cos($angle) * $dist + $_[0];
	my $y = sin($angle) * $dist + $_[1];

	return($x,$y);
}

sub announce {
	my ($msg) = @_;

	my %ann = $server->build_packet(0x0702,
		$msg .
		chr(0x00)
	);
	for ($select->handles) {
		$server->send_packet($_,%ann) if $clients{$_}{'map'};
	}
}

return 1;
