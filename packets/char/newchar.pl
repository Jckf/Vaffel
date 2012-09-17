use warnings;

$server->register_handler(0x0713,sub {
	my ($handle,%packet) = @_;

	if (!$clients{$handle}{'user'}) {
		console(who($handle) . ' is not authenticated!');
		return;
	}

	my ($sex,$hair,$face,$name) = (ord(substr($packet{'args'},0,1)),ord(substr($packet{'args'},2,1)),ord(substr($packet{'args'},3,1)),substr($packet{'args'},7,-1));

	my $shit = $name;
	$shit =~ s/[a-zA-Z0-9]//g;

	if ($clients{$handle}{'charcount'} >= 5) {
		# Too many characters.
		$server->send_packet($handle,$server->build_packet(0x0713,word(0x0004)));
		console(who($handle) . ' tried to create more than 5 characters!');
	} elsif (length($shit)) {
		# Invalid name.
		$server->send_packet($handle,$server->build_packet(0x0713,word(0x0002)));
		console(who($handle) . ' tried to create character with invalid name ' . $name . '!');
	} else {
		my $query = $cdb->prepare("INSERT INTO characters (user,name,sex,face,hair) VALUES (?,?,?,?,?)");
		$query->execute($clients{$handle}{'user'},$name,$sex,$face,$hair);
		if (!$query->rows) {
			# Name in use, or something terrible! =O
			$server->send_packet($handle,$server->build_packet(0x0713,word(0x0002)));
			console(who($handle) . ' tried to create character ' . $name . ', but it failed!');
		} else {
			my $char = $cdb->last_insert_id(undef,undef,undef,undef);
			$query = $cdb->prepare("INSERT INTO inventory (owner,item,`type`,slot) VALUES (?,29,3,3)"); $query->execute($char);
			$query = $cdb->prepare("INSERT INTO inventory (owner,item,`type`,slot) VALUES (?,29,5,6)"); $query->execute($char);
			$query = $cdb->prepare("INSERT INTO inventory (owner,item,`type`,slot) VALUES (?,1,8,7)"); $query->execute($char);
			$query = $cdb->prepare("INSERT INTO inventory (owner,item,`type`,slot) VALUES (?,222 - ?,2,12)"); $query->execute($char,$sex);

			$server->send_packet($handle,$server->build_packet(0x0713,word(0x0000)));
		}
	}
});

return 1;
