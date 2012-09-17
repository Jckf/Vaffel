use warnings;

$chat_commands{'halt'} = sub {
	my ($handle) = @_;

	if ($clients{$handle}{'user'}{'level'} < 4) { # Level 4 doesn't really exist. This requires that the GM elevates himself with /userlevel prior to using /halt.
		console(who($handle) . ' does not have access to the halt command!');
		return;
	}

	announce('The server is going down now!');

	$server->halt();
};

return 1;
