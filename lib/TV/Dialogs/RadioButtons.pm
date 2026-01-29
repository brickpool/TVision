package TV::Dialogs::RadioButtons;
# ABSTRACT: Radio button cluster control based on TCluster

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT = qw(
  TRadioButtons
  new_TRadioButtons
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::Dialogs::Cluster;
use TV::toolkit;

sub TRadioButtons() { __PACKAGE__ }
sub name() { 'TRadioButtons' }
sub new_TRadioButtons { __PACKAGE__->from( @_ ) }

extends TCluster;

# declare global variables
our $button = " ( ) ";

sub draw {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  $self->drawMultiBox( $button, " \x7" );
  return;
}

sub mark {    # $bool ($item)
  my ( $self, $item ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( looks_like_number $item );
  return $item == $self->{value};
}

sub press {    # void ($item)
  my ( $self, $item ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( looks_like_number $item );
  $self->{value} = $item;
  return;
}

sub movedTo {    # void ($item)
  my ( $self, $item ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( looks_like_number $item );
  $self->{value} = $item;
  return;
}

sub setData {    # void (\@rec)
  my ( $self, $rec ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( ref $rec );
  $self->SUPER::setData($rec);
  $self->{sel} = $self->{value};
  return;
} #/ sub setData

1

__END__

=pod

=head1 NAME

TRadioButtons - Radio button cluster control based on TCluster

=head1 DESCRIPTION

C<TRadioButtons> implements a classic radio button group where exactly one item 
is selected at any time. It inherits all navigation, event handling and drawing 
infrastructure from C<TCluster>.  

The control updates its internal value whenever the selection changes or an 
item is pressed. Only one item may be active, and selecting a new item 
automatically deselects the previous one.

=head1 METHODS

=head2 new

 my $rb = TRadioButtons->new(%args);

Creates a new radio button cluster using the given constructor arguments.

=over

=item bounds

Specifies the screen rectangle (I<TRect>) defining the position and size of the 
radio‑button cluster.

=item strings

Contains the linked list of item descriptors (I<TSItem>) used to populate the 
radio‑button labels.

=back

=head2 new_TRadioButtons

 my $rb = new_TRadioButtons($bounds, $aStrings);

Factory wrapper for constructing a C<TRadioButtons> instance.

=head2 draw

 $self->draw();

Renders the radio button group by delegating to C<drawMultiBox()> with a 
radio-style icon set.

=head2 mark

 my $bool = $self->mark($item);

Returns true if the specified item is currently selected.

=head2 press

 $self->press($item);

Selects the pressed item and updates the cluster’s stored value.

=head2 movedTo

 $self->movedTo($item);

Updates the internal value whenever the selection cursor moves to a new item.

=head2 setData

 $self->setData(\@rec);

Sets the stored value from an external record and synchronizes the selection 
index accordingly.

=head1 AUTHORS

=over

=item Turbo Vision Development Team

=item J. Schneider <brickpool@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution). 

=cut
