use warnings;

$server->register_handler(0x079A,sub {
	my ($handle,%packet) = @_;

	if (!$clients{$handle}{'user'}{'id'}) {
		console(who($handle) . ' is not authenticated!');
		event_disconnect($handle);
		return;
	}

	my ($target,$x,$y,$z) = (
		readword(substr($packet{'args'},0,2)),
		readfloat(substr($packet{'args'},2,4)),
		readfloat(substr($packet{'args'},6,4)),
		readword(substr($packet{'args'},10,12))
	);

	player($handle,'target',$target);
	player($handle,'attacking',0);

	if ($clients{$handle}{'movesub'}) {
		&{$clients{$handle}{'movesub'}}($handle,$x,$y);
		delete $clients{$handle}{'movesub'};
		return;
	}

	if (player($handle,'x_dest') == $x && player($handle,'y_dest') == $y) {
		# Ignore this. There is no need to move to the same location twice, but the client seems to think this.
		return;
	}

	if (player($handle,'x') != player($handle,'x_dest') || player($handle,'y') != player($handle,'y_dest')) {
		# Client moved before he reached his previous destination. Calculate how far he got.

		my $x_length = player($handle,'x_dest') - player($handle,'x'); # How far the client should have moved on the X axis,
		my $y_length = player($handle,'y_dest') - player($handle,'y'); # and Y axis.

		my $t_length = (time() - player($handle,'last_move')) / (player($handle,'eta') || 1); # Multiplier for how for we DID get based on how much time has passed.

		player($handle,'x',player($handle,'x') + int($x_length * $t_length));
		player($handle,'y',player($handle,'y') + int($y_length * $t_length));
	}

	my %move = $server->build_packet(0x079A,
		word($clients{$handle}{'id'}) .
		word($target) .
		word(distance(player($handle,'x'),player($handle,'y'),$x,$y)) .
		float($x) .
		float($y) .
		word($z)
	);

	for (keys(%{$world{$clients{$handle}{'map'}}{'players'}})) {
		$server->send_packet($world{$clients{$handle}{'map'}}{'players'}{$_}{'handle'},%move);
	}

	player($handle,'x_dest',$x);
	player($handle,'y_dest',$y);
	player($handle,'last_move',time());
	player($handle,'eta',distance(player($handle,'x'),player($handle,'y'),player($handle,'x_dest'),player($handle,'y_dest')) / player($handle,'mspeed'));
});

return 1;
