use warnings;

$server->register_handler(0x07A8,sub {
	my ($handle,%packet) = @_;

	if (!$clients{$handle}{'user'}{'id'}) {
		console(who($handle) . ' is not authenticated!');
		event_disconnect($handle);
		return;
	}

	my $gate_id = readword(substr($packet{'args'},0,2));

	my $query = $mdb->prepare("SELECT destmap,destx,desty FROM telegates WHERE id=?");
	$query->execute($gate_id);

	if ($query->rows) {
		my $gate = $query->fetchrow_hashref();

		# TODO: Check that the client is close enough to the gate.
		#       It's possible to use a gate that's not even on the same map as you now!

		teleport_player($handle,$gate->{'destmap'},$gate->{'destx'} * 100,$gate->{'desty'} * 100);
	} else {
		console(who($handle) . ' used unknown telegate ' . $gate_id . '!');
		event_disconnect($handle);
	}
});

return 1;
