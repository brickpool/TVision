package TV::Dialogs::ListBox;
# ABSTRACT: 

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

use Carp ();
use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw(
  blessed
  looks_like_number
  readonly
);

use TV::Const qw( EOS );
use TV::Objects::Collection;
use TV::Views::ListViewer;
use TV::toolkit;

sub TListBox() { __PACKAGE__ }
sub name() { 'TListBox' }
sub new_TListBox { __PACKAGE__->from( @_ ) }

extends TListViewer;

# declare attributes
has items => ( is => 'ro' );

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  return $class->SUPER::BUILDARGS( @_, hScrollBar => undef );
}

sub BUILD {    # void (|\%args)
  my $self = shift;
  assert ( blessed $self );
  $self->setRange( 0 );
  return;
}

sub from {    # $obj ($bounds, $aNumCols, $aVScrollBar|undef)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 3 );
  return $class->new( bounds => $_[0], numCols => $_[1], vScrollBar => $_[2] );
}

sub list {    # $collection ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  return $self->{items};
}

sub dataSize {    # $size ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  return 2;
}

sub getData {    # void (\@rec)
  my ( $self, $rec ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( ref $rec );
  $rec->[0] = $self->{items};
  $rec->[1] = $self->{focused};
  return;
} #/ sub getData

sub getText {    # void ($dest, $item, $maxChars)
  my ( $self, undef, $item, $maxChars ) = @_;
  alias: for my $dest ( $_[1] ) {
  assert ( @_ == 4 );
  assert ( blessed $self );
  assert ( !ref $dest and !readonly $dest );
  assert ( looks_like_number $item );
  assert ( looks_like_number $maxChars );
  if ( $self->{items} ) {
    my $src = $self->{items}->at( $item );
    $src = '' unless defined $src;
    $dest = substr( $src, 0, $maxChars );
  } #/ if ( $self->{items} )
  else {
    $dest = EOS;
  }
  return;
  } #/ alias: for my $dest ( $_[1] )
} #/ sub getText

sub newList {    # void ($aList)
  my ( $self, $aList ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( blessed $aList );
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
  my ( $self, $rec ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( ref $rec );
  $self->newList( $rec->[0] );
  $self->focusItem( $rec->[1] );
  $self->drawView();
  return;
} #/ sub setData

1
