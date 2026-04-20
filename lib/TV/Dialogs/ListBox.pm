package TV::Dialogs::ListBox;
# ABSTRACT: Provides a list box dialog with selection handling

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT = qw(
  TListBox
  new_TListBox
);

use Class::Struct;
use PerlX::Assert::PP;
use TV::toolkit;
use TV::toolkit::Params qw( signature );
use TV::toolkit::Types qw(
  Maybe
  is_Object
  :types
);

use TV::Const qw( EOS );
use TV::Objects::NSCollection;
use TV::Views::ListViewer;

struct TListBoxRec => [
  items     => TNSCollection,
  selection => '$',
];

sub TListBox() { __PACKAGE__ }
sub name() { 'TListBox' }
sub new_TListBox { __PACKAGE__->from( @_ ) }

extends TListViewer;

# protected attributes
has items => ( is => 'ro' );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      bounds     => Object,
      numCols    => PositiveOrZeroInt, { alias => 'aNumCols' },
      vScrollBar => Maybe[Object],     { alias => 'aScrollBar' },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return $args;
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->setRange( 0 );
  return;
}

sub from {    # $obj ($bounds, $aNumCols, $aVScrollBar|undef)
  state $sig = signature(
    method => 1,
    pos    => [Object, PositiveOrZeroInt, Maybe[Object]],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], numCols => $args[1], 
    vScrollBar => $args[2] );
}

sub list {    # $collection ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return $self->{items};
}

sub dataSize {    # $size ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  $sig->( @_ );
  state $size = @{ TListBoxRec->new() };
  return $size;
}

sub getData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  my ( $self, $rec ) = $sig->( @_ );
  my $p = TListBoxRec->new(
    items     => $self->{items},
    selection => $self->{focused},
  );
  @$rec[ 0 .. $#$p ] = @$p;
  return;
} #/ sub getData

sub getText {    # void (\$dest, $item, $maxChars)
  state $sig = signature(
    method => Object,
    pos    => [ScalarRef, Int, Int],
  );
  my ( $self, $dest, $item, $maxChars ) = $sig->( @_ );
  if ( $self->{items} ) {
    my $src = $self->{items}->at( $item );
    $src = '' unless defined $src;
    $$dest = substr( $src, 0, $maxChars );
  }
  else {
    $$dest = EOS;
  }
  return;
}

sub newList {    # void ($aList)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $aList ) = $sig->( @_ );
  $self->destroy( $self->{items} );
  $self->{items} = $aList;
  if ( $aList ) {
    $self->setRange( $aList->getCount() );
  }
  else {
    $self->setRange( 0 );
  }
  if ( $self->{range} > 0 ) {
    $self->focusItem( 0 );
  }
  $self->drawView();
  return;
} #/ sub newList

sub setData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  my ( $self, $rec ) = $sig->( @_ );
  my $p = TListBoxRec->new();
  @$p = @$rec[ 0 .. $#$p ];
  $self->newList( $p->items );
  $self->focusItem( $p->selection );
  $self->drawView();
  return;
} #/ sub setData

1
