package TV::Views::Scroller;
# ABSTRACT: Base class for scrolling text windows in Turbo Vision

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TScroller
  new_TScroller
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

use TV::Drivers::Const qw( 
  evBroadcast
);
use TV::Objects::Point;
use TV::Views::Const qw(
  cmScrollBarChanged
  cpScroller
  ofSelectable
  sfActive
  sfDragging
  sfSelected
);
use TV::Views::Palette;
use TV::Views::View;
use TV::toolkit;

sub TScroller() { __PACKAGE__ }
sub name() { 'TScroller' }
sub new_TScroller { __PACKAGE__->from(@_) }

extends TView;

# declare attributes
has delta      => ( is => 'rw' );
has drawLock   => ( is => 'ro' );
has drawFlag   => ( is => 'ro' );
has hScrollBar => ( is => 'ro' );
has vScrollBar => ( is => 'ro' );
has limit      => ( is => 'ro' );

# predeclare private methods
my (
  $showSBar,
);

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  local $Params::Check::PRESERVE_CASE = 1;
  my $args1 = $class->SUPER::BUILDARGS( @_ );
  my $args2 = check( {
    # set 'default' values, init_args => undef
    delta    => { default => TPoint->new(), no_override => 1 },
    drawLock => { default => 0, no_override => 1 },
    drawFlag => { default => !!0, no_override => 1 },
    limit    => { default => TPoint->new(), no_override => 1 },
    # hScrollBar and vScrollBar are 'required' but can be 'undef'
    hScrollBar => {
      required => 1,
      allow    => sub { !defined $_[0] or blessed $_[0] }
    },
    vScrollBar => {
      required => 1,
      allow    => sub { !defined $_[0] or blessed $_[0] }
    },
  } => { @_ } ) || Carp::confess( last_error );
  return { %$args1, %$args2 };
}

sub BUILD {    # void (|\%args)
  my $self = shift;
  assert ( blessed $self );
  $self->{delta}{x} = $self->{delta}{y} = 0;
  $self->{limit}{x} = $self->{limit}{y} = 0;
  $self->{options}   |= ofSelectable;
  $self->{eventMask} |= evBroadcast;
  return;
}

sub from {    # $obj ($bounds, $aHScrollBar|undef, $aVScrollBar|undef)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 3 );
  return $class->new( bounds => $_[0], hScrollBar => $_[1],
    vScrollBar => $_[2] );
}

sub changeBounds {    # void ($bounds)
  my ( $self, $bounds ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( ref $bounds );
  $self->setBounds( $bounds );
  $self->{drawLock}++;
  $self->setLimit( $self->{limit}{x}, $self->{limit}{y} );
  $self->{drawLock}--;
  $self->{drawFlag} = !!0;
  $self->drawView();
  return;
}

my $palette;
sub getPalette {    # $palette ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  $palette ||= TPalette->new(
    data => cpScroller, 
    size => length( cpScroller ),
  );
  return $palette->clone();
}

sub handleEvent {    # void ($event)
  no warnings 'uninitialized';
  my ( $self, $event ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( blessed $event );
  $self->SUPER::handleEvent( $event );
  if ( $event->{what} == evBroadcast
    && $event->{message}{command} == cmScrollBarChanged
    && ( $event->{message}{infoPtr} == $self->{hScrollBar}
      || $event->{message}{infoPtr} == $self->{vScrollBar} )
  ) {
    $self->scrollDraw();
  }
  return;
} #/ sub handleEvent

sub scrollDraw {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  my $d = TPoint->new();

  if ( $self->{hScrollBar} ) {
    $d->{x} = $self->{hScrollBar}{value};
  }
  else {
    $d->{x} = 0;
  }
  if ( $self->{vScrollBar} ) {
    $d->{y} = $self->{vScrollBar}{value};
  }
  else {
    $d->{y} = 0;
  }
  if ( $d->{x} != $self->{delta}{x} || $d->{y} != $self->{delta}{y} ) {
    $self->setCursor(
      $self->{cursor}{x} + $self->{delta}{x} - $d->{x},
      $self->{cursor}{y} + $self->{delta}{y} - $d->{y}
    );
    $self->{delta} = $d;
    if ( $self->{drawLock} ) {
      $self->{drawFlag} = !!1;
    }
    else {
      $self->drawView();
    }
  } #/ if ( $d->{x} != $self->...)
  return;
}

sub scrollTo {    # void ($x, $y)
  my ( $self, $x, $y ) = @_;
  assert ( @_ == 3 );
  assert ( blessed $self );
  assert ( looks_like_number $x );
  assert ( looks_like_number $y );
  $self->{drawLock}++;
  $self->{hScrollBar}->setValue( $x )
    if $self->{hScrollBar};
  $self->{vScrollBar}->setValue( $y )
    if $self->{vScrollBar};
  $self->{drawLock}--;
  $self->checkDraw();
  return;
}

sub setLimit {    # void ($x, $y)
  my ( $self, $x, $y ) = @_;
  assert ( @_ == 3 );
  assert ( blessed $self );
  assert ( looks_like_number $x );
  assert ( looks_like_number $y );
  $self->{limit}{x} = $x;
  $self->{limit}{y} = $y;
  $self->{drawLock}++;
  $self->{hScrollBar}->setParams(
    $self->{hScrollBar}{value},
    0,
    $x - $self->{size}{x},
    $self->{size}{x} - 1,
    $self->{hScrollBar}{arStep}
  ) if $self->{hScrollBar};
  $self->{vScrollBar}->setParams(
    $self->{vScrollBar}{value},
    0,
    $y - $self->{size}{y},
    $self->{size}{y} - 1,
    $self->{vScrollBar}{arStep}
  ) if $self->{vScrollBar};
  $self->{drawLock}--;
  $self->checkDraw();
  return;
}

sub setState {    # void ($aState, $enable)
  my ( $self, $aState, $enable ) = @_;
  assert ( @_ == 3 );
  assert ( blessed $self );
  assert ( looks_like_number $aState );
  assert ( !defined $enable or !ref $enable );
  $self->SUPER::setState( $aState, $enable );
  $self->drawView()
    if $aState & ( sfActive | sfDragging );
  return;
} #/ sub setState

sub checkDraw {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  if ( $self->{drawLock} == 0 && $self->{drawFlag} ) {
    $self->{drawFlag} = !!0;
    $self->drawView();
  }
  return;
} #/ sub checkDraw

sub shutDown {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  $self->{hScrollBar} = undef;
  $self->{vScrollBar} = undef;
  $self->SUPER::shutDown();
  return;
}

$showSBar = sub {    # void ($sBar|undef)
  my ( $self, $sBar ) = @_;
  if ( $sBar ) {
    ( $self->getState( sfActive | sfSelected ) )
      ? $sBar->show()
      : $sBar->hide();
  }
  return;
};

1

__END__

=pod

=head1 NAME

TV::Views::Scroller - Base class TScroller for scrolling text windows.

=head1 SYNOPSIS

  use TV::Objects;
  use TV::Views;

  my $bounds = new_TRect(0, 0, 20, 10);
  my $hBar   = TScrollBar->new(bounds => new_TRect(0, 0, 10, 1));
  my $vBar   = TScrollBar->new(bounds => new_TRect(0, 0, 1, 10));

  my $scroller = TScroller->new(
    bounds      => $bounds,
    aHScrollBar => $hBar,
    aVScrollBar => $vBar
  );

  $scroller->scrollTo(5, 5);
  $scroller->setLimit(100, 50);
  $scroller->handleEvent($event);

=head1 DESCRIPTION

Provides functionality for managing scroll bars, handling events, and updating 
the view when scrolling occurs.

=head1 CONSTRUCTOR

=head2 new

  my $scroller = TScroller->new(%args);

Initializes internal attributes after object construction.  
Sets default values for the fields L</delta>, L</limit>, I<options>, and 
I<eventMask>.

=over

=item bounds

The bounds of the scroller (I<TRect>).

=item aHScrollBar

Optional horizontal scroll bar of the scroller (I<TScrollBar> or undef).

=item aVScrollBar

Optional vertical scroll bar of the scroller (I<TScrollBar> or undef).

=back

=head2 new_TScroller

  my $scroller = new_TScroller($bounds, $aHScrollBar | undef, 
    $aVScrollBar | undef);

Factory constructor for creating a new scroller object.

=head1 ATTRIBUTES

Most of the following attributes are implemented as read-only accessors and
are also used internally by the class:

=over

=item delta

Current scroll offset as a point object (I<TPoint>).  
Represents the difference between the current and previous scroll positions.

=item drawLock

Internal counter for nested draw operations (I<Int>).
Prevents redraw during batch updates.

=item drawFlag

Boolean flag indicating whether a redraw is pending (I<Bool>).

=item aHScrollBar

Reference to the horizontal scroll bar object (I<TScrollBar>).  
I<aHScrollBar> should be undef if you do not want a horizontal scroll bar.

=item aVScrollBar

Reference to the vertical scroll bar object (I<TScrollBar>).  
Similarly to L</aHScrollBar>, I<aVScrollBar> should be undef if you do not want 
a vertical scroll bar. 

=item limit

Maximum scrollable area as a point object (I<TPoint>).  
Defines the horizontal and vertical limits for scrolling.

=back

=head1 METHODS

=head2 changeBounds

  $self->changeBounds($bounds);

Updates the scroller's bounding rectangle and redraws the view.

=head2 checkDraw

  $self->checkDraw();

Ensures the view is redrawn if pending changes exist.

=head2 getPalette

  my $palette = $self->getPalette();

Returns a clone of the scroller's color palette.

=head2 handleEvent

  $self->handleEvent($event);

Processes broadcast events, such as scroll bar changes, and triggers redraw.

=head2 scrollDraw

  $self->scrollDraw();

Updates the cursor position and redraws the view based on scroll bar values.

=head2 scrollTo

  $self->scrollTo($x, $y);

Scrolls the view to the specified coordinates.

=head2 setLimit

  $self->setLimit($x, $y);

Sets the scrolling limits and updates scroll bar parameters.

=head2 setState

  $self->setState($aState, $enable);

Updates the state flags (e.g., active, dragging) and redraws if necessary.

=head2 shutDown

  $self->shutDown();

Cleans up resources and clears references to scroll bars.

=head1 AUTHORS

=over

=item Turbo Vision Development Team

=item J. Schneider <brickpool@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2025-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution). 

=cut
