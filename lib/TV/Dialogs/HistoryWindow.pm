package TV::Dialogs::HistoryWindow;
# ABSTRACT: Window component showing and managing history list items

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  THistoryWindow
  new_THistoryWindow
);

use Carp ();
use TV::toolkit;
use TV::toolkit::Types  qw(
  :is
  :types
);

use TV::Dialogs::Const qw( cpHistoryWindow );
use TV::Dialogs::HistInit;
use TV::Dialogs::HistoryViewer;
use TV::Views::Const qw(
  sbHandleKeyboard
  sbHorizontal
  sbVertical
  wfClose
  wnNoNumber
);
use TV::Views::Palette;
use TV::Views::Window;

sub THistoryWindow() { __PACKAGE__ }
sub new_THistoryWindow { __PACKAGE__->from(@_) }

extends ( TWindow, THistInit );

# protected attributes
has viewer => ( is => 'ro' );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      bounds    => Object,
      historyId => PositiveOrZeroInt,
    ],
    caller_level => +1,
  );
  my ( $class, $args1 ) = $sig->( @_ );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  my $args2 = TWindow->BUILDARGS(
    bounds => $args1->{bounds},
    title  => '',
    number => wnNoNumber,
  );
  my $args3 = THistInit->BUILDARGS(
    cListViewer => $class->can( 'initViewer' )
  );
  return { %$args1, %$args2, %$args3 };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_HashRef $args );
  $self->{flags} = wfClose;
  if ( $self->{createListViewer} ) {
    $self->{viewer} = $self->createListViewer( $self->getExtent(), $self, 
      $args->{historyId} );
    $self->insert( $self->{viewer} ) if $self->{viewer};
  }
  return;
}

sub from {    # $obj ($bounds, $historyId)
  state $sig = signature(
    method => 1,
    pos    => [Object, PositiveOrZeroInt],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], historyId => $args[1] );
}

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cpHistoryWindow, 
    size => length( cpHistoryWindow ),
  );
  return $palette->clone();
}

sub getSelection {    # void (\$dest)
  state $sig = signature(
    method => Object,
    pos    => [ScalarRef],
  );
  my ( $self, $dest ) = @_;
  $self->{viewer}->getText( $dest, $self->{viewer}{focused}, 255 );
  return;
}

sub initViewer {    # $listViewer ($r, $win, $historyId)
  state $sig = signature(
    method => 1,
    pos    => [Object, Object, PositiveOrZeroInt],
  );
  my ( $class, $r, $win, $historyId ) = $sig->( @_ );
  $r->grow( -1, -1 );
  return THistoryViewer->new(
    bounds     => $r,
    hScrollBar => $win->standardScrollBar( sbHorizontal | sbHandleKeyboard ),
    vScrollBar => $win->standardScrollBar( sbVertical | sbHandleKeyboard ),
    historyId  => $historyId,
  );
} #/ sub initViewer

1
