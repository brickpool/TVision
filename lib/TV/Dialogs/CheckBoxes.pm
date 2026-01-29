package TV::Dialogs::CheckBoxes;
# ABSTRACT: Multi‑item checkbox cluster control based on TCluster

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT = qw(
  TCheckBoxes
  new_TCheckBoxes
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::Dialogs::Cluster;
use TV::toolkit;

sub TCheckBoxes() { __PACKAGE__ }
sub name() { 'TCheckBoxes' }
sub new_TCheckBoxes { __PACKAGE__->from( @_ ) }

extends TCluster;

# declare global variables
our $button = " [ ] ";

sub draw {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  $self->drawMultiBox( $button, " X" );
  return;
}

sub mark {    # $bool ($item)
  my ( $self, $item ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( looks_like_number $item );
  return ( $self->{value} & ( 1 << $item ) ) != 0;
}

sub press {    # void ($item)
  my ( $self, $item ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( looks_like_number $item );
  $self->{value} = $self->{value} ^ ( 1 << $item );
  return;
}

1

__END__

=pod

=pod

=head1 NAME

TCheckBoxes - Multi‑item checkbox cluster control based on TCluster

=head1 DESCRIPTION

C<TCheckBoxes> implements a multi‑selection checkbox group where each item can 
be toggled independently.  

The control stores all selection states inside a bitmask, with one bit per item.  
It inherits drawing, navigation and event dispatching logic from C<TCluster>.  
Only the marking behavior and toggle logic are specialized to support 
multi‑state selection.

=head1 METHODS

=head2 new

 my $cb = TCheckBoxes->new(%args);

Creates a new checkbox cluster using the given constructor parameters.

=over

=item bounds

Specifies the screen rectangle (I<TRect>) defining the position and size of the 
checkbox cluster.

=item strings

Contains the linked list of item descriptors (I<TSItem>) used to populate the 
checkbox labels.

=back

=head2 new_TCheckBoxes

 my $cb = new_TCheckBoxes($bounds, $aStrings);

Factory wrapper for constructing a C<TCheckBoxes> instance.

=head2 draw

 $self->draw();

Renders the full checkbox cluster using C<drawMultiBox()> with a checkbox 
marker.

=head2 mark

 my $bool = $self->mark($item);

Returns true if the bit corresponding to the item index is currently set.

=head2 press

 $self->press($item);

Toggles the bit assigned to the given item index in the internal value mask.

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
