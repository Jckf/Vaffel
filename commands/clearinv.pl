use warnings;

$chat_commands{'clearinv'} = sub {
	my ($handle,@args) = @_;

	for (12..139) {
		if (${player($handle,'items')}{$_}) {
			move_item($handle,$_,0);
		}
	}
};

return 1;
