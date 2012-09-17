use warnings;

$server->register_handler(0x0808,sub {
	my ($handle,%packet) = @_;

	$server->fakelag_decrease($handle); # Allows this packet to be excempt from fakelag check.
});

return 1;
