use warnings;

$server->register_handler(0x0783,sub {
	my ($handle,%packet) = @_;

	if (!$clients{$handle}{'user'}{'id'}) {
		console(who($handle) . ' is not authenticated!');
		event_disconnect($handle);
		return;
	}

	my $chatter = substr($packet{'args'},0,-1);

	if (substr($chatter,0,1) eq '/') {
		my ($command,@args) = split(/ /,substr($chatter,1));
		if ($chat_commands{$command}) {
			&{$chat_commands{$command}}($handle,@args);
		} else {
			console(who($handle) . ' executed unknown command /' . $command . '!');
		}
		return;
	}

	my %chat = $server->build_packet(0x0783,
		word($clients{$handle}{'id'}) .
		$chatter .
		chr(0x00)
	);

	my %players = &map($handle,'players');
	for (keys(%players)) {
		$server->send_packet($players{$_}{'handle'},%chat);
	}
});

return 1;
