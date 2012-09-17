use warnings;

$chat_commands{'ann'} = sub {
	my ($handle,@args) = @_;

	if ($clients{$handle}{'user'}{'level'} < 2) {
		console(who($handle) . ' does not have access to the ann command!');
		return;
	}

	announce(player($handle,'name') . '>' . join(' ',@args));
};

return 1;
