package TV::Views::ListViewer;
# ABSTRACT: Base class for list viewers in Turbo Vision

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TListViewer
  new_TListViewer
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
  readonly
);

use TV::Const qw( EOS );
use TV::Drivers::Const qw(
  :evXXXX
  kbUp
  kbDown
  kbLeft
  kbRight
  kbPgDn
  kbPgUp
  kbHome
  kbEnd
  kbCtrlPgDn
  kbCtrlPgUp
  meDoubleClick
);
use TV::Drivers::Util qw(
  ctrlToArrow
);
use TV::Objects::Point;
use TV::Views::Const qw(
  cmScrollBarChanged
  cmScrollBarClicked
  cmListItemSelected
  cpListViewer
  ofFirstClick
  ofSelectable
  :sfXXXX
);
use TV::Views::DrawBuffer;
use TV::Views::Palette;
use TV::Views::View;
use TV::Views::Util qw( message );
use TV::toolkit;

sub TListViewer() { __PACKAGE__ }
sub name() { 'TListViewer' }
sub new_TListViewer { __PACKAGE__->from(@_) }

# import global variables
use vars qw(
  $showMarkers
  $specialChars
  $emptyText
);
{
  no strict 'refs';
  *showMarkers  = \${ TView . '::showMarkers'  };
  *specialChars = \${ TView . '::specialChars' };
}

extends TView;

# declare global variables
our $emptyText = "<empty>";

# declare attributes
has hScrollBar => ( is => 'rw' );
has vScrollBar => ( is => 'rw' );
has numCols    => ( is => 'rw' );
has topItem    => ( is => 'rw' );
has focused    => ( is => 'rw' );
has range      => ( is => 'rw' );

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  local $Params::Check::PRESERVE_CASE = 1;
  my $args1 = $class->SUPER::BUILDARGS( @_ );
  my $args2 = check( {
    # set 'default' values, init_args => undef
    topItem => { default => 0, no_override => 1 },
    focused => { default => 0, no_override => 1 },
    range   => { default => 0, no_override => 1 },
    # 'required' arguments
    numCols => { required => 1, defined => 1, allow => qr/^\d+$/ },
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
  my ( $arStep, $pgStep );
  $self->{options}   |= ofFirstClick | ofSelectable;
  $self->{eventMask} |= evBroadcast;
  if ( $self->{vScrollBar} ) {
    if ( $self->{numCols} == 1 ) {
      $pgStep = $self->{size}{y} - 1;
      $arStep = 1;
    }
    else {
      $pgStep = $self->{size}{y} * $self->{numCols};
      $arStep = $self->{size}{y};
    }
    $self->{vScrollBar}->setStep( $pgStep, $arStep );
  } #/ if ( $self->{vScrollBar...})

  if ( $self->{hScrollBar} ) {
    $self->{hScrollBar}->setStep(
      int( $self->{size}{x} / $self->{numCols} ), 
      1
    );
  }
  return;
}

sub from {    # $obj ($bounds, $aNumCols, $aHScrollBar|undef, $aVScrollBar|undef)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 4 );
  return $class->new( bounds => $_[0], numCols => $_[1], hScrollBar => $_[2],
    vScrollBar => $_[3] );
}

sub changeBounds {    # void ($bounds)
  my ( $self, $bounds ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( ref $bounds );
  $self->SUPER::changeBounds( $bounds );
  if ( $self->{hScrollBar} ) {
    $self->{hScrollBar}->setStep(
      int( $self->{size}{x} / $self->{numCols} ), 
      $self->{hScrollBar}{arStep}
    );
  }
  if ( $self->{vScrollBar} ) {
    $self->{vScrollBar}->setStep( 
      $self->{size}{y}, 
      $self->{vScrollBar}{arStep}
    );
  }
  return;
}

sub draw {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );

  my ( $i, $j, $item );
  my ( $normalColor, $selectedColor, $focusedColor, $color );
  my ( $colWidth, $curCol, $indent );
  my $b = TDrawBuffer->new;
  my $scOff;

  if ( ( $self->{state} & ( sfSelected | sfActive ) ) 
      == ( sfSelected | sfActive )
  ) {
    $normalColor   = $self->getColor( 1 );
    $focusedColor  = $self->getColor( 3 );
    $selectedColor = $self->getColor( 4 );
  }
  else {
    $normalColor   = $self->getColor( 2 );
    $selectedColor = $self->getColor( 4 );
  }

  if ( $self->{hScrollBar} ) {
    $indent = $self->{hScrollBar}{value};
  }
  else {
    $indent = 0;
  }

  $colWidth = int( $self->{size}{x} / $self->{numCols} ) + 1;
  for ( $i = 0 ; $i < $self->{size}{y} ; $i++ ) {
    for ( $j = 0 ; $j < $self->{numCols} ; $j++ ) {
      $item   = $j * $self->{size}{y} + $i + $self->{topItem};
      $curCol = $j * $colWidth;
      if ( ( ( $self->{state} & ( sfSelected | sfActive ) ) 
            == ( sfSelected | sfActive ) )
        && $self->{focused} == $item
        && $self->{range} > 0 )
      {
        $color = $focusedColor;
        $self->setCursor( $curCol + 1, $i );
        $scOff = 0;
      }
      elsif ( $item < $self->{range} && $self->isSelected( $item ) ) {
        $color = $selectedColor;
        $scOff = 2;
      }
      else {
        $color = $normalColor;
        $scOff = 4;
      }
      $b->moveChar( $curCol, ' ', $color, $colWidth );
      if ( $item < $self->{range} ) {
        my $text;
        $self->getText( $text, $item, $colWidth + $indent );
        my $buf = substr( $text, $indent, $colWidth );
        $b->moveStr( $curCol + 1, $buf, $color );
        if ( $showMarkers ) {
          $b->putChar( $curCol, $specialChars->[$scOff] );
          $b->putChar( $curCol + $colWidth - 2, $specialChars->[ $scOff + 1 ] );
        }
      } #/ if ( $item < $self->{range...})
      elsif ( $i == 0 && $j == 0 ) {
        $b->moveStr( $curCol + 1, $emptyText, $self->getColor( 1 ) );
      }

      $b->moveChar( $curCol + $colWidth - 1, chr 179, $self->getColor( 5 ), 1 );
    } #/ for ( $j = 0 ; $j < $self...)

    $self->writeLine( 0, $i, $self->{size}{x}, 1, $b );
  } #/ for ( $i = 0 ; $i < $self...)

  return;
} #/ sub draw

sub focusItem {    # void ($item)
  my ( $self, $item ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( looks_like_number $item );
  $self->{focused} = $item;
  if ( $self->{vScrollBar} ) {
    $self->{vScrollBar}->setValue( $item );
  }
  else {
    $self->drawView;
  }
  if ( $item < $self->{topItem} ) {
    if ( $self->{numCols} == 1 ) {
      $self->{topItem} = $item;
    }
    else {
      $self->{topItem} = $item - ( $item % $self->{size}{y} );
    }
  }
  else {
    if ( $item >= $self->{topItem} + $self->{size}{y} * $self->{numCols} ) {
      if ( $self->{numCols} == 1 ) {
        $self->{topItem} = $item - $self->{size}{y} + 1;
      }
      else {
        $self->{topItem} = $item - ( $item % $self->{size}{y} ) -
          ( $self->{size}{y} * ( $self->{numCols} - 1 ) );
      }
    } #/ if ( $item >= $self->{...})
  } #/ else [ if ( $item < $self->{topItem...})]
  return;
} #/ sub focusItem

my $palette;
sub getPalette {    # $palette ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  $palette ||= TPalette->new(
    data => cpListViewer, 
    size => length( cpListViewer ),
  );
  return $palette->clone();
}

sub getText {    # void ($dest, $item, $width)
  my ( $self, undef, $item, $width ) = @_;
  alias: for my $dest ( $_[1] ) {
  assert ( @_ == 4 );
  assert ( blessed $self );
  assert ( !ref $dest and !readonly $dest );
  assert ( looks_like_number $item );
  assert ( looks_like_number $width );
  $dest = EOS;
  return;
  } #/ alias: for my $dest ( $_[1] )
}

sub isSelected {    # $bool ($item)
  my ( $self, $item ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( looks_like_number $item );
  return $item == $self->{focused};
}

sub handleEvent {    # void ($event)
  no warnings 'uninitialized';
  my ( $self, $event ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( blessed $event );

  my $mouse;
  my $colWidth;
  my ($oldItem, $newItem );
  my $count;
  my $mouseAutosToSkip = 4;

  $self->SUPER::handleEvent( $event );

  if ( $event->{what} == evMouseDown ) {
    $colWidth = int( $self->{size}{x} / $self->{numCols} ) + 1;
    $oldItem  = $self->{focused};
    $mouse = $self->makeLocal( $event->{mouse}{where} );
    if ( $self->mouseInView( $event->{mouse}{where} ) ) {
      $newItem = $mouse->{y} 
        + ( $self->{size}{y} * int( $mouse->{x} / $colWidth ) ) 
          + $self->{topItem};
    }
    else {
      $newItem = $oldItem;
    }
    $count = 0;
    DO: { do {
      if ( $newItem != $oldItem ) {
        $self->focusItemNum( $newItem );
        $self->drawView();
      }
      $oldItem = $newItem;
      $mouse = $self->makeLocal( $event->{mouse}{where} );
      if ( $self->mouseInView( $event->{mouse}{where} ) ) {
        $newItem = $mouse->{y} 
          + ( $self->{size}{y} * int( $mouse->{x} / $colWidth ) ) 
            + $self->{topItem};
      }
      else {
        if ( $self->{numCols} == 1 ) {
          if ( $event->{what} == evMouseAuto ) {
            $count++;
          }
          if ( $count == $mouseAutosToSkip ) {
            $count = 0;
            if ( $mouse->{y} < 0 ) {
              $newItem = $self->{focused} - 1;
            }
            elsif ( $mouse->{y} >= $self->{size}{y} ) {
              $newItem = $self->{focused} + 1;
            }
          }
        } #/ if ( $self->{numCols} ...)
        else {
          if ( $event->{what} == evMouseAuto ) {
            $count++;
          }
          if ( $count == $mouseAutosToSkip ) {
            $count = 0;
            if ( $mouse->{x} < 0 ) {
              $newItem = $self->{focused} - $self->{size}{y};
            }
            elsif ( $mouse->{x} >= $self->{size}{x} ) {
              $newItem = $self->{focused} + $self->{size}{y};
            }
            elsif ( $mouse->{y} < 0 ) {
              $newItem = $self->{focused} 
                - ( $self->{focused} % $self->{size}{y} );
            }
            elsif ( $mouse->{y} > $self->{size}{y} ) {
              $newItem = $self->{focused} 
                - ( $self->{focused} % $self->{size}{y} ) 
                  + $self->{size}{y} - 1;
            }
          } #/ if ( $count == $mouseAutosToSkip)
        } #/ else [ if ( $self->{numCols} ...)]
      } #/ else [ if ( $self->mouseInView...)]
      last DO
        if $event->{mouse}{eventFlags} & meDoubleClick;

    } while ( $self->mouseEvent( $event, evMouseMove | evMouseAuto ) ) }
    $self->focusItemNum( $newItem );
    $self->drawView;
    if ( ( $event->{mouse}{eventFlags} & meDoubleClick )
      && $self->{range} > $newItem
    ) {
      $self->selectItem( $newItem );
    }
    $self->clearEvent( $event );
  } #/ if ( $event->{what} ==...)

  elsif ( $event->{what} == evKeyDown ) {
    if ( $event->{keyDown}{charScan}{charCode} eq ' '
      && $self->{focused} < $self->{range}
    ) {
      $self->selectItem( $self->{focused} );
      $newItem = $self->{focused};
    }
    else {
      SWITCH: for ( ctrlToArrow( $event->{keyDown}{keyCode} ) ) {
        kbUp == $_ and do {
          $newItem = $self->{focused} - 1;
          last;
        };
        kbDown == $_ and do {
          $newItem = $self->{focused} + 1;
          last;
        };
        kbRight == $_ and do {
          if ( $self->{numCols} > 1 ) {
            $newItem = $self->{focused} + $self->{size}{y};
          }
          else {
            return;
          }
          last;
        };
        kbLeft == $_ and do {
          if ( $self->{numCols} > 1 ) {
            $newItem = $self->{focused} - $self->{size}{y};
          }
          else {
            return;
          }
          last;
        };
        kbPgDn == $_ and do {
          $newItem = $self->{focused} + $self->{size}{y} * $self->{numCols};
          last;
        };
        kbPgUp == $_ and do {
          $newItem = $self->{focused} - $self->{size}{y} * $self->{numCols};
          last;
        };
        kbHome == $_ and do {
          $newItem = $self->{topItem};
          last;
        };
        kbEnd == $_ and do {
          $newItem =
            $self->{topItem} + ( $self->{size}{y} * $self->{numCols} ) - 1;
          last;
        };
        kbCtrlPgDn == $_ and do {
          $newItem = $self->{range} - 1;
          last;
        };
        kbCtrlPgUp == $_ and do {
          $newItem = 0;
          last;
        };
        DEFAULT: {
          return;
        }
      } #/ SWITCH: for ( ctrlToArrow( $event...))
    } #/ else [ if ( $event->{keyDown}...)]
    $self->focusItemNum( $newItem );
    $self->drawView();
    $self->clearEvent( $event );
  } #/ elsif ( $event->{what} ==...)

  elsif ( $event->{what} == evBroadcast ) {
    if ( $self->{options} & ofSelectable ) {
      if ( $event->{message}{command} == cmScrollBarClicked 
        && ( $event->{message}{infoPtr} == $self->{hScrollBar}
          || $event->{message}{infoPtr} == $self->{vScrollBar} )
      ) {
        $self->focus();    # BUG FIX <<----- Change
      }
      elsif ( $event->{message}{command} == cmScrollBarChanged ) {
        if ( $self->{vScrollBar} == $event->{message}{infoPtr} ) {
          $self->focusItemNum( $self->{vScrollBar}{value} );
          $self->drawView();
        }
        elsif ( $self->{hScrollBar} == $event->{message}{infoPtr} ) {
          $self->drawView();
        }
      }
    } #/ if ( $self->{options} ...)
  } #/ elsif ( $event->{what} ==...)
  return;
} #/ sub handleEvent

sub selectItem {    # void ($item)
  my ( $self, $item ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( looks_like_number $item );
  message( $self->{owner}, evBroadcast, cmListItemSelected, $self );
  return;
}

sub setRange {    # void ($aRange)
  my ( $self, $aRange ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( looks_like_number $aRange );
  $self->{range} = $aRange;

  # BUG FIX - EFW - Tue 06/26/95
  if ( $self->{focused} >= $aRange ) {
    $self->{focused} = ( $aRange - 1 >= 0 ) ? $aRange - 1 : 0;
  }

  if ( $self->{vScrollBar} ) {
    $self->{vScrollBar}->setParams( $self->{focused}, 0, $aRange - 1,
      $self->{vScrollBar}{pgStep}, $self->{vScrollBar}{arStep} );
  }
  else {
    $self->drawView();
  }
  return;
} #/ sub setRange

sub setState {    # void ($aState, $enable)
  my ( $self, $aState, $enable ) = @_;
  assert ( @_ == 3 );
  assert ( blessed $self );
  assert ( looks_like_number $aState );
  assert ( !defined $enable or !ref $enable );
  $self->SUPER::setState( $aState, $enable );
  if ( $aState & (sfSelected | sfActive | sfVisible) ) {
    if ( $self->{hScrollBar} ) {
      if ( $self->getState(sfActive) && $self->getState(sfVisible) ) {
        $self->{hScrollBar}->show();
      } 
      else {
        $self->{hScrollBar}->hide();
      }
    }
    if ( $self->{vScrollBar} ) {
      if ( $self->getState(sfActive) && $self->getState(sfVisible) ) {
        $self->{vScrollBar}->show();
      } 
      else {
        $self->{vScrollBar}->hide();
      }
    }
    $self->drawView();
  }
  return;
} #/ sub setState

sub focusItemNum {    # void ($item)
  my ( $self, $item ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( looks_like_number $item );
  if ( $item < 0 ) {
    $item = 0;
  }
  elsif ( $item >= $self->{range} && $self->{range} > 0 ) {
    $item = $self->{range} - 1;
  }
  $self->focusItem( $item )
    if $self->{range};
  return;
} #/ sub focusItemNum

sub shutDown {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  $self->{hScrollBar} = undef;
  $self->{vScrollBar} = undef;
  $self->SUPER::shutDown();
  return;
}

1

__END__

=pod

=head1 NAME

TListViewer - Base class for list viewers in Turbo Vision

=head1 SYNOPSIS

  use TV::Objects;
  use TV::Views;

  # create horizontal and vertical scroll bars
  my $hBar = TScrollBar->new(
    bounds => TRect->new( ax => 0, ay => 0, bx => 10, by => 1 )
  );
  my $vBar = TScrollBar->new(
    bounds => TRect->new( ax => 0, ay => 0, bx => 1, by => 10 )
  );

  # create list viewer with one column
  my $bounds = TRect->new( ax => 0, ay => 0, bx => 30, by => 10 );
  my $lv     = new_TListViewer( $bounds, 1, $hBar, $vBar );

  # subclassing example: override getText() and selectItem()
  package My::ListViewer;
  use parent 'TV::Views::ListViewer';

  sub getText {
    my ( $self, $dest, $item, $width ) = @_;
    # fill $dest with the text for the given item (like a C char*)
    $dest = sprintf "Item %d", $item;
    $_[1] = substr( $dest, 0, $width );
    return;
  }

  sub selectItem {
    my ( $self, $item ) = @_;
    # handle activation of the item (double click or space key)
    ...
  }

=head1 DESCRIPTION

C<TListViewer> is the Turbo Vision base class for list viewers.
It implements the generic behaviour for displaying a list of items in one
or more columns, including scrolling, keyboard navigation and mouse
interaction.

List viewer classes are expected to subclass C<TListViewer> and override at 
least C<getText()> and usually C<selectItem()> in order to provide the actual 
data and the selection behaviour.

=head1 CONSTRUCTOR

=head2 new

  my $lv = TListViewer->new( bounds => $bounds, numCols => $numCols, 
    hScrollBar => $hScrollBar, vScrollBar => $vScrollBar );

Creates a new C<TListViewer> instance.

=over 4

=item * C<$bounds>

A C<TRect> object describing the view's bounds.

=item * C<$numCols>

Number of columns the list viewer should use. The items are laid out
column-wise, using the same algorithm as the original C++ implementation.

=item * C<$hScrollBar>

An optional C<TScrollBar> object used as horizontal scroll bar. It may be
C<undef>.

=item * C<$vScrollBar>

An optional C<TScrollBar> object used as vertical scroll bar. It may be
C<undef>.

=back

=head2 new_TListViewer

  my $lv = new_TListViewer( $bounds, $numCols, $hScrollBar, $vScrollBar );

Convenience constructor that forwards to C<new()> with named parameters.

=head1 ATTRIBUTES

The following attributes are implemented as read/write accessors and
are also used internally by the class:

=head2 hScrollBar

  my $sb = $lv->hScrollBar;
  $lv->hScrollBar( $new_sb );

Horizontal scroll bar associated with the list viewer. May be C<undef>.

=head2 vScrollBar

  my $sb = $lv->vScrollBar;
  $lv->vScrollBar( $new_sb );

Vertical scroll bar associated with the list viewer. May be C<undef>.

=head2 numCols

  my $cols = $lv->numCols;
  $lv->numCols( 2 );

Number of columns used to display the items.

=head2 topItem

  my $idx = $lv->topItem;
  $lv->topItem( $idx );

Index of the first item that is currently visible in the list (top-left
position). This is updated automatically when the focus moves outside the
visible region.

=head2 focused

  my $idx = $lv->focused;
  $lv->focused( $idx );

Index of the item that currently has the focus. The focused item is
highlighted when the view is active and selected.

=head2 range

  my $count = $lv->range;
  $lv->range( $count );

Number of items in the list. This is used as the upper bound for
navigation and drawing. The C<setRange()> method should normally be used
to update this value.

=head1 METHODS

=head2 changeBounds

  $lv->changeBounds( $bounds );

Adjusts the list viewer to a new bounding rectangle. The scroll bar step
sizes are recalculated based on the new size, in the same way as in the
original Turbo Vision implementation.

=head2 draw

  $lv->draw();

Draws the contents of the list viewer. This method uses C<getText()>,
C<isSelected()> and the global marker variables from C<TView> to render
each item into a C<TDrawBuffer>. It is normally not necessary to override
this method in subclasses.

=head2 focusItem

  $lv->focusItem( $index );

Moves the focus to the given item index and updates the vertical scroll
bar and C<topItem> if necessary so that the focused item is visible.

=head2 focusItemNum

  $lv->focusItemNum( $index );

Like C<focusItem()>, but clamps the index to the valid range
C<[0 .. range-1]> and ignores the call if C<range> is zero.

=head2 getPalette

  my $pal = $lv->getPalette();

Returns a clone of the static palette used by the list viewer. The
palette data is defined by the C<cpListViewer> constant.

=head2 handleEvent

  $lv->handleEvent( $event );

Handles keyboard, mouse and broadcast events.

=over 4

=item *

Mouse events (C<evMouseDown>, C<evMouseMove>, C<evMouseAuto>) are used to
track the mouse position over the list and to change the focused item
accordingly, including auto-scrolling when the mouse leaves the view.

=item *

Key events (C<evKeyDown>) are used for navigation (arrow keys, page up/down,
home/end, control page up/down) and for activating the focused item with the
space bar.

=item *

Broadcast events (C<evBroadcast>) are used to react to scroll bar clicks
and changes (C<cmScrollBarClicked>, C<cmScrollBarChanged>) and to keep the
list viewer in sync with the associated scroll bars.

=back

=head2 isSelected

  my $bool = $lv->isSelected( $index );

Returns a boolean value indicating whether the given item is currently
selected. The default implementation returns true only if the index
matches C<focused>. Subclasses may override this method to implement
multi-selection.

=head2 selectItem

  $lv->selectItem( $index );

Called when an item is activated (for example by double clicking or by
pressing the space bar). The default implementation sends a broadcast
message C<cmListItemSelected> to the owner view. Subclasses typically
override this method to implement application-specific behaviour.

=head2 setRange

  $lv->setRange( $count );

Sets the number of items in the list and updates C<range>, the focused
item and the vertical scroll bar parameters. This method corresponds to
C<TListViewer::setRange()> in the original C++ code and includes the
same bug fix that prevents the focused index from going past the last
item.

=head2 setState

  $lv->setState( $stateMask, $enable );

Updates the view's state flags and shows or hides the scroll bars
depending on the C<sfActive> and C<sfVisible> states. The method also
requests a redraw of the view when the relevant state bits change.

=head2 shutDown

  $lv->shutDown();

Shuts down the list viewer and clears the references to its scroll bars
before delegating to C<TView::shutDown()>. After C<shutDown()> has been
called, C<hScrollBar> and C<vScrollBar> will be C<undef>.

=head1 OVERRIDABLE METHODS

Subclasses are expected to override the following methods:

=head2 getText

  $lv->getText( $dest, $item, $width );

Fills C<$dest> with the text for the given item index. The text may be longer 
than C<$width>; the drawing code will only use the first C<$width> characters 
starting at the current horizontal scroll position.

=head2 isSelected

  my $bool = $lv->isSelected( $index );

May be overridden to implement multi-selection or other selection
policies. The default implementation returns true only for the focused
item.

=head2 selectItem

  $lv->selectItem( $index );

May be overridden to react to item activation (double click, space key)
in an application-specific way.

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
