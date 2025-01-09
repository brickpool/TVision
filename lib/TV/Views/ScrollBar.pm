package TV::Views::ScrollBar;
# ABSTRACT: Scroll bar class for window components in Turbo Vision

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TScrollBar
  new_TScrollBar
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use List::Util qw( min max );
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::Drivers::Const qw( 
  :evXXXX
  :kbXXXX
);
use TV::Drivers::Util qw( ctrlToArrow );
use TV::Objects::DrawBuffer;
use TV::Objects::Point;
use TV::Objects::Rect;
use TV::Views::Const qw(
  :cmXXXX
  cpScrollBar
  :gfXXXX
  :sbXXXX
  sfVisible
);
use TV::Views::Palette;
use TV::Views::View;
use TV::Views::Util qw( message );
use TV::toolkit;

sub TScrollBar() { __PACKAGE__ }
sub name() { 'TScrollBar' }
sub new_TScrollBar { __PACKAGE__->from(@_) }

extends TView;

# declare global variables
our $vChars = "\x1E\x1F\xB1\xFE\xB2";    # cp437: "▲▼░■▒"
our $hChars = "\x11\x10\xB1\xFE\xB2";    # cp437: "◄►░■▒"

# declare attributes
has value  => ( is => 'rw', default => sub { 0 } );
has minVal => ( is => 'rw', default => sub { 0 } );
has maxVal => ( is => 'rw', default => sub { 0 } );
has pgStep => ( is => 'rw', default => sub { 1 } );
has arStep => ( is => 'rw', default => sub { 1 } );
has chars  => ( is => 'rw', default => sub { "\0" x 5 } );

# predeclare private methods
my (
  $getPartCode,
);

sub BUILD {    # void (|\%args)
  my $self = shift;
  assert ( blessed $self );
  if ( $self->{size}{x} == 1 ) {
    $self->{growMode} = gfGrowLoX | gfGrowHiX | gfGrowHiY;
    $self->{chars}    = $vChars;
  }
  else {
    $self->{growMode} = gfGrowLoY | gfGrowHiX | gfGrowHiY;
    $self->{chars}    = $hChars;
  }
  return;
}

sub draw {    # void ()
  my $self = shift;
  assert ( blessed $self );
  $self->drawPos( $self->getPos() );
  return;
}

my $palette;
sub getPalette {    # $palette ()
  my $self = shift;
  assert ( blessed $self );
  $palette ||= TPalette->new(
    data => cpScrollBar, 
    size => length( cpScrollBar ),
  );
  return $palette->clone();
}

my $mouse = TPoint->new();
my ( $p, $s );
my $extent = TRect->new();

sub handleEvent {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( blessed $self );
  assert ( blessed $event );
  
  my $Tracking;
  my ( $i, $clickPart );

  $self->SUPER::handleEvent( $event );
  SWITCH: for ( $event->{what} ) {
    $_ == evMouseDown and do {
      # Clicked()
      message( $self->owner, evBroadcast, cmScrollBarClicked, $self );
      $mouse  = $self->makeLocal( $event->{mouse}{where} );
      $extent = $self->getExtent();
      $extent->grow( 1, 1 );
      $p = $self->getPos();
      $s = $self->getSize() - 1;
      $clickPart = $self->$getPartCode();
      if ( $clickPart != sbIndicator ) {
        do {
          $mouse = $self->makeLocal( $event->{mouse}{where} );
          if ( $self->$getPartCode() eq $clickPart ) {
            $self->setValue( $self->{value} + $self->scrollStep( $clickPart ) );
          }
        } while ( $self->mouseEvent( $event, evMouseAuto ) );
      }
      else {
        do {
          $mouse = $self->makeLocal( $event->{mouse}{where} );
          $Tracking = $extent->contains( $mouse );
          if ( $Tracking ) {
            $i = $self->{size}{x} == 1 
              ? $mouse->{y} 
              : $mouse->{x};
            $i = max( $i, 1);
            $i = min( $i, $s - 1);
          }
          else {
            $i = $self->getPos();
          }
          if ( $i != $p ) {
            $self->drawPos( $i );
            $p = $i;
          }
        } while ( $self->mouseEvent( $event, evMouseMove ) );
        if ( $Tracking && $s > 2 ) {
          $s -= 2;
          $self->setValue(
            int(
              (
                  ( $p - 1 ) 
                * ( $self->{maxVal} - $self->{minVal} ) 
                + ( $s >> 1 )
              ) / $s + $self->{minVal}
            )
          );
        }
      } #/ else [ if ( $clickPart != sbIndicator)]
      $self->clearEvent( $event );
      last;
    };
    $_ == evKeyDown and do {
      if ( $self->{state} & sfVisible ) {
        $clickPart = sbIndicator;
        if ( $self->{size}{y} == 1 ) {
          SWITCH: for ( ctrlToArrow( $event->{keyDown}{keyCode} ) ) {
            $_ == kbLeft and do {
              $clickPart = sbLeftArrow;
              last;
            };
            $_ == kbRight and do {
              $clickPart = sbRightArrow;
              last;
            };
            $_ == kbCtrlLeft and do {
              $clickPart = sbPageLeft;
              last;
            };
            $_ == kbCtrlRight and do {
              $clickPart = sbPageRight;
              last;
            };
            $_ == kbHome and do {
              $i = $self->{minVal};
              last;
            };
            $_ == kbEnd and do {
              $i = $self->{maxVal};
              last;
            };
            DEFAULT: {
              return;
            }
          }
        }
        else {
          SWITCH: for ( ctrlToArrow( $event->{keyDown}{keyCode} ) ) {
            $_ == kbUp and do {
              $clickPart = sbUpArrow;
              last;
            };
            $_ == kbDown and do {
              $clickPart = sbDownArrow;
              last;
            };
            $_ == kbPgUp and do {
              $clickPart = sbPageUp;
              last;
            };
            $_ == kbPgDn and do {
              $clickPart = sbPageDown;
              last;
            };
            $_ == kbCtrlPgUp and do {
              $i = $self->{minVal};
              last;
            };
            $_ == kbCtrlPgDn and do {
              $i = $self->{maxVal};
              last;
            };
            DEFAULT: {
              return;
            }
          }
        }
        # Clicked
        message( $self->owner, evBroadcast, cmScrollBarClicked, $self );
        $i = $self->{value} + $self->scrollStep( $clickPart )
          if $clickPart != sbIndicator;
        $self->setValue( $i );
        $self->clearEvent( $event );
      } #/ if ( ( $self->{state} ...))
      last;
    }; #/ do
    }
  return;
} #/ sub handleEvent

sub scrollDraw {    # void ()
  my $self = shift;
  assert ( blessed $self );
  message( $self->owner, evBroadcast, cmScrollBarChanged, $self );
  return;
}

sub scrollStep {    # $steps ($part)
  my ( $self, $part ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $part );
  my $step = ( $part & 2 ) ? $self->{pgStep} : $self->{arStep};
  return ( $part & 1 ) ? $step : -$step;
}

sub setParams {    # void ($aValue, $aMin, $aMax, $aPgStep, $aArStep)
  my ( $self, $aValue, $aMin, $aMax, $aPgStep, $aArStep ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $aValue );
  assert ( looks_like_number $aMin );
  assert ( looks_like_number $aMax );
  assert ( looks_like_number $aPgStep );
  assert ( looks_like_number $aArStep );
  $aMax   = max( $aMax, $aMin );
  $aValue = max( $aValue, $aMin );
  $aValue = min( $aValue, $aMax );
  my $sValue = $self->{value};
  if ( $sValue != $aValue
    || $self->{minVal} != $aMin
    || $self->{maxVal} != $aMax
  ) {
    $self->{value}  = $aValue;
    $self->{minVal} = $aMin;
    $self->{maxVal} = $aMax;
    $self->drawView();
    $self->scrollDraw()
      if $sValue != $aValue;
  } #/ if ( $sValue != $aValue...)
  $self->{pgStep} = $aPgStep;
  $self->{arStep} = $aArStep;
  return;
} #/ sub setParams

sub setRange {    # void ($aMin, $aMax)
  my ( $self, $aMin, $aMax ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $aMin );
  assert ( looks_like_number $aMax );
  $self->setParams( $self->{value}, $aMin, $aMax, $self->{pgStep},
    $self->{arStep} );
  return;
}

sub setStep {    # void ($aPgStep, $aArStep)
  my ( $self, $aPgStep, $aArStep ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $aPgStep );
  assert ( looks_like_number $aArStep );
  $self->setParams( $self->{value}, $self->{minVal}, $self->{maxVal}, $aPgStep,
    $aArStep );
  return;
}

sub setValue {    # void ($aValue)
  my ( $self, $aValue ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $aValue );
  $self->setParams( $aValue, $self->{minVal}, $self->{maxVal}, $self->{pgStep},
    $self->{arStep} );
  return;
}

sub drawPos {    # void ($pos)
  my ( $self, $pos ) = @_;
  my $b = TDrawBuffer->new();
  my $s = $self->getSize() - 1;
  $b->moveChar( 0, substr($self->{chars}, 0, 1), $self->getColor( 2 ), 1 );
  if ( $self->{maxVal} == $self->{minVal} ) {
    $b->moveChar( 1, substr($self->{chars}, 4, 1), $self->getColor( 1 ), $s-1 );
  }
  else {
    $b->moveChar( 1, substr($self->{chars}, 2, 1), $self->getColor( 1 ), $s-1 );
    $b->moveChar( $pos, substr($self->{chars}, 3, 1), $self->getColor( 3 ), 1 );
  }
  $b->moveChar( $s, substr( $self->{chars}, 1, 1), $self->getColor( 2 ), 1 );
  $self->writeBuf( 0, 0, $self->{size}{x}, $self->{size}{y}, $b );
  return;
} #/ sub drawPos

sub getPos {    # $pos ()
  my $self = shift;
  assert ( blessed $self );
  my $r = $self->{maxVal} - $self->{minVal};
  return 1 
    if $r == 0;
  return int(
    (
        ( $self->{value} - $self->{minVal} ) 
      * ( $self->getSize() - 3 )
      + ( $r >> 1 )
    ) / $r + 1
  );
} #/ sub getPos

sub getSize {   # $size ()
  my $self = shift;
  assert ( blessed $self );
  return $self->{size}{x} == 1 
    ? $self->{size}{y} 
    : $self->{size}{x};
}

$getPartCode = sub {    # $int ()
  my $self = shift;
  my $part = -1;
  if ( $extent->contains( $mouse ) ) {
    my $mark = $self->{size}{x} == 1 ? $mouse->{y} : $mouse->{x};

    # Check for vertical or horizontal size of 2
    if ( ( $self->{size}{x} == 1 && $self->{size}{y} == 2 )
      || ( $self->{size}{x} == 2 && $self->{size}{y} == 1 ) )
    {
      # Set 'part' to left or right arrow only
      if ( $mark < 1 ) {
        $part = sbLeftArrow;
      } 
      elsif ( $mark == $p ) {
        $part = sbRightArrow;
      }
    }
    else {
      if ( $mark == $p ) {
        $part = sbIndicator;
      }
      else {
        if ( $mark < 1 ) {
          $part = sbLeftArrow;
        }
        elsif ( $mark < $p ) {
          $part = sbPageLeft;
        }
        elsif ( $mark < $s ) {
          $part = sbPageRight;
        }
        else {
          $part = sbRightArrow;
        }
        $part += 4 
          if $self->{size}{x} == 1;
      } #/ else [ if ( $mark == $self->{...})]
    } #/ else [ if ( ( $self->{size}->...))]
  } #/ if ( $extent->...)
  return $part;
};

1

__END__

=pod

=head1 NAME

TScrollBar - Scroll bar class for window components in Turbo Vision

=head1 SYNOPSIS

  use TV::Views;

  my $scrollBar = TScrollBar->new(bounds => $bounds);
  $scrollBar->draw();

=head1 DESCRIPTION

The C<TScrollBar> class is used to create scroll bars for window components in
Turbo Vision. It provides methods for drawing the scroll bar and managing its
appearance and behavior.

=head1 ATTRIBUTES

=over

=item value

The current value of the scroll bar. (Int)

=item minVal

The minimum value of the scroll bar. (Int)

=item maxVal

The maximum value of the scroll bar. (Int)

=item pgStep

The page step value of the scroll bar. (Int)

=item arStep

The arrow step value of the scroll bar. (Int)

=back

=head1 METHODS

=head2 new

  my $scrollBar = TScrollBar->new(bounds => $bounds);

Initializes an instance of C<TScrollBar> with the specified bounds.

=over

=item bounds

The bounds of the view (TRect).

=back

=head2 draw

  $self->draw();

Draws the scroll bar on the screen.

=head2 drawPos

  $self->drawPos($pos);

=head2 getPalette

  my $palette = $self->getPalette();

Returns the scroll bar's color palette.

=head2 getPos

  my $pos = $self->getPos();

=head2 getSize

  my $size = $self->getSize();

=head2 handleEvent

  $self->handleEvent($event);

Handles an event sent to the scroll bar.

=head2 scrollDraw

  $self->scrollDraw();

Draws the scroll bar's thumb and arrows.

=head2 scrollStep

  my $steps = scrollStep($part);

Scrolls the scroll bar by a specified step.

=head2 setParams

  $self->setParams($aValue, $aMin, $aMax, $aPgStep, $aArStep);

Sets the parameters of the scroll bar.

=head2 setRange

  $self->setRange($aMin, $aMax);

Sets the range of the scroll bar.

=head2 setStep

  $self->setStep($aPgStep, $aArStep);

Sets the step values of the scroll bar.

=head2 setValue

  $self->setValue($aValue);

Returns the current value of the scroll bar.

=head1 AUTHORS

=over

=item Turbo Vision Development Team

=item J. Schneider <brickpool@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2025 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution). This documentation is provided under the same terms 
as the Turbo Vision library itself.

=cut
