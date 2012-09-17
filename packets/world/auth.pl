use warnings;

$server->register_handler(0x070B,sub {
	my ($handle,%packet) = @_;

	my ($user_id,$pass) = (readword(substr($packet{'args'},0,4)),substr($packet{'args'},4));

	my $query = $mdb->prepare("SELECT name,`char`,level FROM users WHERE id=? AND pass=?");
	$query->execute($user_id,$pass);

	if (!$query->rows) {
		# Invalid user or password.
		console(who($handle) . ' sent invalid user ID or password!');
		event_disconnect($handle);
	} else {
		# Ok =)
		my $user = $query->fetchrow_hashref();

		$clients{$handle}{'user'}{'id'} = $user_id;
		$clients{$handle}{'user'}{'name'} = $user->{'name'};
		$clients{$handle}{'user'}{'level'} = $user->{'level'};

		$query = $cdb->prepare("SELECT * FROM characters WHERE name=?"); # Bad wildcard.
		$query->execute($user->{'char'});

		if ($query->rows) {
			my $char = $query->fetchrow_hashref();

			# Login okay.
			$server->send_packet($handle,$server->build_packet(0x070C,
				chr(0) .
				dword(0x87654321) .
				dword(0x00000000)
			));

			$clients{$handle}{'id'} = client_id($char->{'map'});
			$clients{$handle}{'map'} = $char->{'map'};

			%{$world{$clients{$handle}{'map'}}{'players'}{$clients{$handle}{'id'}}} = %{{
				'handle'	=> $handle,
				'id'		=> $char->{'id'},
				'name'		=> $user->{'char'},
				'level'		=> $char->{'level'},
				'sex'		=> $char->{'sex'},
				'job'		=> $char->{'job'},
				'face'		=> $char->{'face'},
				'hair'		=> $char->{'hair'},
				'stance'	=> 3, # 1:Sit. 2:Walk. 3:Run. 4:Drive. TODO: Check if overweight.
				'target'	=> 0,
				'attacking'	=> 0,
				'x'			=> $char->{'x'},
				'y'			=> $char->{'y'},
				'x_dest'	=> $char->{'x'},
				'y_dest'	=> $char->{'y'},
				'spawned'	=> 0,
				'hp'		=> $char->{'hp'},
				'mp'		=> $char->{'mp'},
				'hp_max'	=> 126,	# TODO.
				'mp_max'	=> 75,	# TODO.
				'exp'		=> $char->{'exp'},
				'zulie'		=> $char->{'zulie'},
				'str'		=> $char->{'str'},
				'dex'		=> $char->{'dex'},
				'int'		=> $char->{'int'},
				'con'		=> $char->{'con'},
				'cha'		=> $char->{'cha'},
				'sen'		=> $char->{'sen'},
				'mspeed'	=> 425, # TODO: Calculate it based to stats, gear and whatnot. Also check if overweight.
				'stat_p'	=> $char->{'stat_p'},
				'skill_p'	=> $char->{'skill_p'},
				'union'		=> $char->{'union'},
				'fame'		=> $char->{'fame'},
				'union1_p'	=> $char->{'union1_p'},
				'union2_p'	=> $char->{'union2_p'},
				'union3_p'	=> $char->{'union3_p'},
				'union4_p'	=> $char->{'union4_p'},
				'union5_p'	=> $char->{'union5_p'}
			}};

			$query = $cdb->prepare("SELECT * FROM inventory WHERE owner=?"); # Nuu wildcard! =(
			$query->execute(player($handle,'id'));

			my %inventory; # This is a fix for people who have nothing in their inventory.
			%{$world{$clients{$handle}{'map'}}{'players'}{$clients{$handle}{'id'}}{'items'}} = %inventory;

			while (my $item = $query->fetchrow_hashref()) {
				%{$world{$clients{$handle}{'map'}}{'players'}{$clients{$handle}{'id'}}{'items'}{$item->{'slot'}}} = %{{
					'db_id'		=> $item->{'id'},
					'id'		=> $item->{'item'},
					'type'		=> $item->{'type'},
					'amount'	=> $item->{'amount'},
					'durability'=> $item->{'durability'},
					'lifespan'	=> $item->{'lifespan'},
					'appraised'	=> $item->{'appraised'},
					'stats'		=> $item->{'stats'},
					'refined'	=> $item->{'refined'},
					'socket'	=> $item->{'socket'},
					'gem'		=> $item->{'gem'}
				}};
			}

			# Player data.
			my $equipment = '';
			for (2,3,5,6,1,4,7,8) {
				if (${player($handle,'items')}{$_}) {
					$equipment .=
						word(${player($handle,'items')}{$_}{'id'}) .
						word(${player($handle,'items')}{$_}{'refined'})
					;
				} else {
					$equipment .= dword(0); # Nothing equipped to slot $_.
				}
			}
			$server->send_packet($handle,$server->build_packet(0x0715,
				chr(player($handle,'sex')) . # Character sex,
				word($clients{$handle}{'map'}) . # Current map.
				float(player($handle,'x')) . # Pos x.
				float(player($handle,'y')) . # Pos y.
				word(0) .
				dword(player($handle,'face')) . # Face.
				dword(player($handle,'hair')) . # Hair.
				$equipment . # Equipment.
				chr(0) .
				word(0x140F) .
				word(player($handle,'job')) . # Job.
				chr(player($handle,'union')) . # Union ID.
				chr(0) .
				chr(player($handle,'fame')) . # Union fame.
				word(player($handle,'str')) . # Str.
				word(player($handle,'dex')) . # Dex.
				word(player($handle,'int')) . # Int.
				word(player($handle,'con')) . # Con.
				word(player($handle,'cha')) . # Cha.
				word(player($handle,'sen')) . # Sen.
				word(player($handle,'hp')) . # Current HP.
				word(player($handle,'mp')) . # Current MP.
				word(player($handle,'exp')) . # Exp.
				word(0) .
				word(player($handle,'level')) . # Level.
				word(player($handle,'stat_p')) . # Stat points.
				word(player($handle,'skill_p')) . # Skill points.
				word(0x6464) .
				qword(0) .
				word(player($handle,'union1_p')) . # Union points 1.
				word(player($handle,'union2_p')) . # Union points 2.
				word(player($handle,'union3_p')) . # Union points 3.
				word(player($handle,'union4_p')) . # Union points 4.
				word(player($handle,'union5_p')) . # Union points 5.
				(chr(0) x 19) .
				word(0) . # Stamina.
				(chr(0) x 320) .
				word(0) . # Has cart and/or castle gear?
				(word(0) x 2) .
				(word(0) x 60) .
				(word(0) x 30) .
				(word(0) x 30) .
				(word(0) x 200) .
				(word(0) x 42) .
				(word(0) x 48) .
				dword(player($handle,'id')) . # Character ID.
				(chr(0) x 80) .
				player($handle,'name') .
				chr(0)
			));

			# Inventory data.
			my $inventory = '';
			for (0..139) {
				if (${player($handle,'items')}{$_}) {
					$inventory .=
						dword(item_head(%{${player($handle,'items')}{$_}})) .
						dword(item_body(%{${player($handle,'items')}{$_}}))
					;
				} else {
					$inventory .= qword(0); # Nothing in inventory slot $_.
				}
				$inventory .=
					dword(0) .
					word(0)
				;
			}
			$server->send_packet($handle,$server->build_packet(0x0716,
				qword(player($handle,'zulie')) . # Zulie.
				$inventory
			));

			# Quest data.
			$server->send_packet($handle,$server->build_packet(0x071B,
				(word(0) x 5) . # Episode.
				(word(0) x 3) . # Job.
				(word(0) x 7) . # Planet.
				(word(0) x 10) . # Union.
				(( # Quests.
					word(0) . # Quest ID.
					dword(0) . # Remaining time.
					(word(0) x 10) . # Variables.
					(chr(0) x 4) . # Switches.
					(( # Items.
						(dword(0) x 2) . # Item head and data.
						dword(0) .
						word(0)
					) x 6)
				) x 10) .
				(chr(0) x 64) . # Quest flags.
				(chr(0) x 12) . # Clan?
				(chr(0) x 8) . # Clan?
				(( # Wishlist.
					(dword(0) x 3) . word(0)
				) x 30)
			));
		} else {
			console(who($handle) . ' selected invalid character ' . $user->{'char'} . '!');
			event_disconnect($handle);
		}
	}
});

return 1;
