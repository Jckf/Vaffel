use warnings;

$chat_commands{'rehash'} = sub {
	my ($handle,@args) = @_;

	if ($clients{$handle}{'user'}{'level'} < 2) {
		console(who($handle) . ' does not have access to the rehash command!');
		return;
	}

	announce(player($handle,'name') . ' is rehashing the server!');

	console('Reloading packet handlers...');
	for (<./packets/world/*.pl>) {
		my $filename = lc($_);
		$filename =~ s/.*\/(.+)\..+/$1/i;
		console('    ' . $filename);
		do $_ or announce('Could not load packet handler ' . $_ . '!');
	}

	console('Reloading chat commands...');
	for (<./commands/*.pl>) {
		my $filename = lc($_);
		$filename =~ s/.*\/(.+)\..+/$1/i;
		console('    ' . $filename);
		do $_ or announce('Could not load chat command ' . $_ . '!');
	}
};

return 1;
