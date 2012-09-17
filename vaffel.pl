#!/usr/bin/perl
use strict;
use warnings;
use threads;

$ENV{'vaffel_threads'} = 1;

for ('login','char') {
	threads->new(sub {
		do $_ . '.pl';
		warn $! if $!;
		warn $@ if $@;
	});
	sleep 1;
}

do 'world.pl';
warn $! if $!;
warn $@ if $@;

exit;
