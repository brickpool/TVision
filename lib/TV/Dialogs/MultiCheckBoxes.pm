package TV::Dialogs::MultiCheckBoxes;
# ABSTRACT: 

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT = qw(
  TMultiCheckBoxes
  new_TMultiCheckBoxes
);

use Carp ();
use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Params::Check qw(
  check
  last_error
);
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::Dialogs::Cluster;
use TV::toolkit;

sub TMultiCheckBoxes() { __PACKAGE__ }
sub name() { 'TMultiCheckBoxes' }
sub new_TMultiCheckBoxes { __PACKAGE__->from( @_ ) }

extends TCluster;

# declare attributes
has selRange => ( is => 'ro' );
has flags    => ( is => 'ro' );
has states   => ( is => 'ro' );

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  local $Params::Check::PRESERVE_CASE = 1;
  my $args1 = $class->SUPER::BUILDARGS( @_ );
  my $args2 = check( {
    selRange => { required => 1, default => 0, strict_type => 1 },
    flags    => { required => 1, default => 0, strict_type => 1 },
    states   => { required => 1, defined => 1, allow => sub { !ref $_[0] } },
  } => { @_ } ) || Carp::confess( last_error );
  return { %$args1, %$args2 };
} #/ sub BUILDARGS

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  $self->{states} = undef;
  return;
}

sub from {    # $obj ($bounds, $aStrings|undef, $aSelRange, $aFlags, $aStates)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 5 );
  return $class->new(
    bounds => $_[0], strings => $_[1], selRange => $_[2],
    flags  => $_[3], states  => $_[4]
  );
}

sub dataSize {    # $size ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  return 1;
}

sub draw {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  $self->drawMultiBox( " [ ] ", $self->{states} );
  return;
}

sub getData {    # void (\@p)
  my ( $self, $p ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( ref $p );
  $p->[0] = $self->{value};
  $self->drawView();
  return;
} #/ sub getData

sub multiMark {    # $int ($item)
  my ( $self, $item ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( looks_like_number $item );
  return ( 
    $self->{value} &
    ( ( $self->{flags} & 0xff ) << ( $item * ( $self->{flags} >> 8 ) ) ) 
  ) >> ( $item * ( $self->{flags} >> 8 ) );
}

sub press {    # void ($item)
  my ( $self, $item ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( looks_like_number $item );
  my $flo = $self->{flags} & 0xff;
  my $fhi = $self->{flags} >> 8;

  my $curState =
    ( $self->{value} & ( $flo << ( $item * $fhi ) ) ) >> ( $item * $fhi );

  $curState--;
  if ( $curState >= $self->{selRange} || $curState < 0 ) {
    $curState = $self->{selRange} - 1;
  }

  $self->{value} = ( $self->{value} & ~( $flo << ( $item * $fhi ) ) ) |
    ( $curState << ( $item * $fhi ) );
  return;
} #/ sub press

sub setData {    # void (\@p)
  my ( $self, $p ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( ref $p );
  $self->{value} = 0+ $p->[0];
  $self->drawView();
  return;
} #/ sub setData

1

__END__

=pod

=head1 NAME

TMultiCheckBoxes - Multi‑state checkbox cluster control based on TCluster

=head1 SYNOPSIS

  use TV::Objects;
  use TV::Dialogs;

  my $bounds = TRect->new( ax => 0, ay => 0, bx => 30, by => 5 );

  my $items = { value => 'Low',  next =>
              { value => 'Med',  next =>
              { value => 'High', next => undef }}};

  my $mcb = new_TMultiCheckBoxes(
      $bounds,
      $items,
      3,        # selRange   (number of states per item)
      0x0201,   # flags      (low byte = mask, high byte = shift per item)
      " -+"     # states     (characters representing each possible state)
  );

=head1 DESCRIPTION

C<TMultiCheckBoxes> provides a multi‑state checkbox control where each item can 
cycle through a configurable number of states.  

The state of each item is stored inside a packed bitfield, with a configurable
field width and state mask derived from the C<flags> attribute.  

The control inherits its navigation and layout behavior from C<TCluster>, while
implementing its own multi‑state display and toggling logic.

=head1 ATTRIBUTES

=over

=item selRange

Defines the number of distinct states each item may cycle through (I<Int>).

=item flags

Bitfield descriptor controlling how state values are packed (I<Int>):
low byte = state mask, high byte = bit‑shift step per item.

=item states

A string containing the per‑state marker characters used for drawing (I<Str>).

=back

=head1 METHODS

=head2 new

  my $obj = TMultiCheckBoxes->new(%args);

Constructs a new multi‑state checkbox cluster with the specified parameters.

=head2 new

  my $obj = TMultiCheckBoxes->new(%args);

Creates a new multi‑state checkbox cluster using the following arguments:

=over

=item bounds

A C<TRect> object defining the screen position and size of the cluster.

=item strings

A linked C<TSItem> list containing the textual labels for each item.

=item selRange

The number of different states each item may cycle through (I<Int>).

=item flags

A packed integer describing the bit‑mask (low byte) and bit‑shift step (high 
byte) used for encoding item states (I<Int>).

=item states

A string containing the characters used to visually represent each possible 
state (I<Str>).

=back

=head2 new_TMultiCheckBoxes

  my $obj = new_TMultiCheckBoxes($bounds, $aStrings, $range, $flags, $states);

Factory wrapper for creating a TMultiCheckBoxes instance.

=head2 dataSize

  my $size = $self->dataSize();

Returns the number of scalars transferred by getData/setData (always 1).

=head2 draw

  $self->draw();

Renders the multi‑state cluster using the supplied state marker table.

=head2 getData

  $self->getData(\@p);

Writes the packed state bitfield into the output record.

=head2 multiMark

  my $state = $self->multiMark($item);

Returns the current state index for the specified item extracted from the 
bitfield.

=head2 press

  $self->press($item);

Advances the state of the given item and wraps around according to selRange.

=head2 setData

  $self->setData(\@p);

Updates the internal state bitfield from external input.

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
