use warnings;

$server->register_handler(0x0808,sub {
	# Eat this packet.
});

return 1;
