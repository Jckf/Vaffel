use warnings;

$server->register_handler(0x0784,sub {
	my ($handle,%packet) = @_;

	my ($name,$msg) = split(/\0/,$packet{'args'},2);

	my $to;
	for my $client (keys(%clients)) {
		if ($world{$clients{$client}{'map'}}{'players'}{$clients{$client}{'id'}}{'name'} eq $name) {
			$to = $world{$clients{$client}{'map'}}{'players'}{$clients{$client}{'id'}}{'handle'};
			last;
		}
	}

	if ($to) {
		$server->send_packet($to,$server->build_packet(0x0784,
			player($handle,'name') .
			chr(0) .
			$msg .
			chr(0)
		));
	} else {
		$server->send_packet($handle,$server->build_packet(0x0784,
			$name .
			word(0)
		));
	}
});

return 1;
