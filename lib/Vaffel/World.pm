use strict;
use warnings;
use Vaffel::Instance;

package Vaffel::World;

sub new {
	my ($class,%args) = @_;
	my $self = {};

	$self->{'instances'} = ();

	bless($self,$class);
	return $self;
}

sub new_instance {
	my ($self,$instance) = @_;

	my $id = @{$self->{'instances'}};
	$self->{'instancecs'}[$id] = Vaffel::Instance->new($id);

	return \$self->{'instancecs'}[$id];
}

sub get_instance {
	my ($self,$id) = @_;

	return \$self->{'instances'}[$id];
}
