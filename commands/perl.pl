use warnings;

$chat_commands{'perl'} = sub {
	my ($handle,@args) = @_;

	if ($clients{$handle}{'user'}{'level'} < 3) {
		console(who($handle) . ' does not have access to the perl command!');
		return;
	}

	announce('return ' . eval(join(' ',@args)) . '; # ' . $@ . ' ' . $!);
};

return 1;
