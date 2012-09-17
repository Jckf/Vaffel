use warnings;

$server->register_handler(0x07A7,sub {
	my ($handle,%packet) = @_;

	my $drop = readword(substr($packet{'args'},0,2));

	if (!drop($handle,$drop,'amount')) { # We read amount just to read something. This is really a check to see if the drop exists.
		console(who($handle) . ' tried to pick up an invalid drop!');
		return;
	}

	my $remove = 0;
	my $data = word($drop);

	if (!drop($handle,$drop,'owner') || drop($handle,$drop,'owner') == $clients{$handle}{'id'} || time() - drop($handle,$drop,'time') >= 30) { # TODO: Party check.
		if (drop($handle,$drop,'type') == 1) {
			# Zulie.
			player($handle,'zulie',player($handle,'zulie') + drop($handle,$drop,'amount'));

			my $query = $cdb->prepare("UPDATE characters SET zulie=? WHERE id=?");
			$query->execute(player($handle,'zulie'),player($handle,'id'));

			$data .=
				word(0) .
				chr(0) .
				dword(0xCCCCCCDF) .
				dword(drop($handle,$drop,'amount')) .
				dword(0xCCCCCCCC) .
				word(0xCCCC)
			;
		} else {
			my $slot;
			for (12..139) {
				if (!${player($handle,'items')}{$_}) {
					$slot = $_;
					last;
				}
			}

			$data .=
				chr(0) .
				chr($slot) .
				chr(0) .
				dword(item_head(%{$world{$clients{$handle}{'map'}}{'drops'}{$drop}})) .
				dword(item_body(%{$world{$clients{$handle}{'map'}}{'drops'}{$drop}})) .
				dword(0) .
				word(0)
			;

			# Put it in a temporary fake slot.
			%{$world{$clients{$handle}{'map'}}{'players'}{$clients{$handle}{'id'}}{'items'}{0}} = %{$world{$clients{$handle}{'map'}}{'drops'}{$drop}};

			# Then put it in properly.
			move_item($handle,0,$slot);
		}
		$remove = 1;
	} else {
		$data .= chr(2);
	}

	$server->send_packet($handle,$server->build_packet(0x07A7,$data));

	if ($remove) {
		# TODO: If in party, send message to let others know what the pickup was.

		for (keys(%{$world{$clients{$handle}{'map'}}{'players'}})) {
			clear_map_client_from_player($world{$clients{$handle}{'map'}}{'players'}{$_}{'handle'},$drop);
		}

		delete $world{$clients{$handle}{'map'}}{'drops'}{$drop};
	}
});

return 1;
