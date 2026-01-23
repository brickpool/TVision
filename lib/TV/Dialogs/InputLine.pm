package TV::Dialogs::InputLine;
# ABSTRACT: Input line dialog control for Turbo Vision

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TInputLine
  new_TInputLine
);

use Carp ();
use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use List::Util qw( min max );
use Params::Check qw(
  check
  last_error
);
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::Dialogs::Const qw( cpInputLine );
use TV::Drivers::Const qw(
  :evXXXX
  kbShift
  kbLeft
  kbRight
  kbHome
  kbEnd
  kbBack
  kbDel
  kbIns
  meDoubleClick
);
use TV::Drivers::Util qw( ctrlToArrow );
use TV::Validate::Const qw( :vtXXXX );
use TV::Views::Const qw(
  ofSelectable
  ofFirstClick
  :sfXXXX
);
use TV::Views::DrawBuffer;
use TV::Views::Palette;
use TV::Views::View;
use TV::toolkit;

sub TInputLine() { __PACKAGE__ }
sub name() { 'TInputLine' }
sub new_TInputLine { __PACKAGE__->from(@_) }

extends TView;

use constant CONTROL_Y => 25;

# declare global variables
our $rightArrow = "\x10";
our $leftArrow  = "\x11";

# declare attributes
has data        => ( is => 'rw' );
has maxLen      => ( is => 'ro' );
has curPos      => ( is => 'rw' );
has firstPos    => ( is => 'rw' );
has selStart    => ( is => 'ro' );
has selEnd      => ( is => 'ro' );

has validator   => ( is => 'ro' );
has anchor      => ( is => 'ro' );
has oldAnchor   => ( is => 'ro' );    # New to save another bit of state info
has oldData     => ( is => 'ro' );
has oldCurPos   => ( is => 'ro' );
has oldFirstPos => ( is => 'ro' );
has oldSelStart => ( is => 'ro' );
has oldSelEnd   => ( is => 'ro' );

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  local $Params::Check::PRESERVE_CASE = 1;
  my $args1 = $class->SUPER::BUILDARGS( @_ );
  my $args2 = check( {
    # init_args => undef
    oldCurPos   => { no_override => 1 },
    oldFirstPos => { no_override => 1 },
    oldSelStart => { no_override => 1 },
    oldSelEnd   => { no_override => 1 },
    # set 'default' value, init_args => undef
    data        => { default => '', no_override => 1 },
    curPos      => { default => 0,  no_override => 1 },
    firstPos    => { default => 0,  no_override => 1 },
    selStart    => { default => 0,  no_override => 1 },
    selEnd      => { default => 0,  no_override => 1 },
    anchor      => { default => -1, no_override => 1 },
    oldAnchor   => { default => -1, no_override => 1 },
    oldData     => { default => '', no_override => 1 },
    # note: 'validator' can be undef
    validator => { allow => sub { !defined $_[0] or blessed $_[0] } },
    # 'required' attributes
    maxLen => { required => 1, defined => 1, allow => qr/^\d+$/ },
  } => { @_ } ) || Carp::confess( last_error );
  return { %$args1, %$args2 };
}

sub BUILD {    # void (|\%args)
  my $self = shift;
  assert ( blessed $self );
  $self->{state} |= sfCursorVis;
  $self->{options} |= ofSelectable | ofFirstClick;
  return;
}

sub from {    # $obj ($bounds, $aMaxLen, |$aValid)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ >= 2 && @_ <= 3 );
  return $class->new( bounds => $_[0], maxLen => $_[1], validator => $_[2] );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  $self->{data} = undef;
  $self->{oldData} = undef;
  $self->destroy( $self->{validator} );
  return;
}

sub dataSize {    # $dSize ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  my $dSize = 0;

  if ( $self->{validator} ) {
    $dSize = $self->{validator}->transfer( $self->{data}, undef, vtDataSize );
  }
  if ( $dSize == 0 ) {
    $dSize = 1;    # In Perl, this must be the number of entries in the list
  }
  return $dSize;
} #/ sub dataSize

sub draw {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );

  my ( $l, $r );
  my $b = TDrawBuffer->new();
  my $color = $self->{state} & sfFocused
            ? $self->getColor( 2 )
            : $self->getColor( 1 );

  $b->moveChar( 0, ' ', $color, $self->{size}{x} );
  my $buf = substr( $self->{data}, $self->{firstPos}, $self->{size}{x} - 2 );
  $b->moveStr( 1, $buf, $color );

  if ( $self->canScroll( 1 ) ) {
    $b->moveChar( $self->{size}{x} - 1, $rightArrow, $self->getColor( 4 ), 1 );
  }
  if ( $self->{state} & sfSelected ) {
    if ( $self->canScroll( -1 ) ) {
      $b->moveChar( 0, $leftArrow, $self->getColor( 4 ), 1 );
    }
    $l = $self->{selStart} - $self->{firstPos};
    $r = $self->{selEnd} - $self->{firstPos};
    $l = max( 0, $l );
    $r = min( $self->{size}{x}, 2 );
    if ( $l < $r ) {
      $b->moveChar( $l + 1, 0, $self->getColor( 3 ), $r - $l );
    }
  } #/ if ( ( $self->{state} ...))
  $self->writeLine( 0, 0, $self->{size}{x}, $self->{size}{y}, $b );
  $self->setCursor( $self->{curPos} - $self->{firstPos} + 1, 0 );
  return;
} #/ sub draw

sub getData {    # void (\@rec)
  my ( $self, $rec ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( ref $rec );
  if ( !$self->{validator}
    || !$self->{validator}->transfer( $self->{data}, $rec, vtGetData ) )
  {
    assert ( $self->dataSize() );
    $rec->[0] = $self->{data};
  }
} #/ sub getData

my $palette;
sub getPalette {    # $palette ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  $palette ||= TPalette->new(
    data => cpInputLine, 
    size => length( cpInputLine ),
  );
  return $palette->clone();
}

sub handleEvent {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( blessed $event );
  # Home, Left Arrow, Right Arrow, End, Ctrl-Left Arrow, Ctrl-Right Arrow
  my @padKeys = ( 0x47, 0x4b, 0x4d, 0x4f, 0x73, 0x74 );
  $self->SUPER::handleEvent( $event );

  my ( $delta, $i );
  return unless ( $self->{state} & sfSelected );
  SWITCH: for ( $event->{what} ) {
    evMouseDown == $_ and do {
      if ( $self->canScroll( $delta = $self->mouseDelta( $event ) ) ) {
        do {
          if ( $self->canScroll( $delta ) ) {
            $self->{firstPos} += $delta;
            $self->drawView();
          }
        } while mouseEvent( $event, evMouseAuto );
      } #/ if ( $self->canScroll(...))
      elsif ( $event->{mouse}{eventFlags} & meDoubleClick ) {
        $self->selectAll( 1 );
      }
      else {
        $self->{anchor} = $self->mousePos( $event );
        do {
          if ( $event->{what} == evMouseAuto ) {
            $delta = $self->mouseDelta( $event );
            if ( $self->canScroll( $delta ) ) {
              $self->{firstPos} += $delta;
            }
          }
          $self->{curPos} = $self->mousePos( $event );
          $self->adjustSelectBlock();
          $self->drawView();
        } while mouseEvent( $event, evMouseMove | evMouseAuto );
      } #/ else [ if ( $self->canScroll(...))]
      clearEvent( $event );
      last;
    };

    evKeyDown == $_ and do {
      $self->saveState();
      $event->{keyDown}{keyCode} =
        ctrlToArrow( $event->{keyDown}{keyCode} );
      my $scanCode  = $event->{keyDown}{charScan}{scanCode};
      my $isPad    = grep { $_ == $scanCode } @padKeys;
      my $hasShift = $event->{keyDown}{controlKeyState} & kbShift;
      if ( $isPad && $hasShift ) {
        $event->{keyDown}{charScan}{charCode} = 0;
        if ( $self->{anchor} < 0 ) {
          $self->{anchor} = $self->{curPos};
        }
      }
      else {
        $self->{anchor} = -1;
      }
      SWITCH: for ( $event->{keyDown}{keyCode} ) {
        kbLeft == $_ and do {
          if ( $self->{curPos} > 0 ) {
            $self->{curPos}--;
          }
          last;
        };
        kbRight == $_ and do {
          if ( $self->{curPos} < length( $self->{data} ) ) {
            $self->{curPos}++;
          }
          last;
        };
        kbHome == $_ and do {
          $self->{curPos} = 0;
          last;
        };
        kbEnd == $_ and do {
          $self->{curPos} = length( $self->{data} );
          last;
        };
        kbBack == $_ and do {
          if ( $self->{curPos} > 0 ) {
            substr( $self->{data}, $self->{curPos} - 1, 1, '' );
            $self->{curPos}--;
            if ( $self->{firstPos} > 0 ) {
              $self->{firstPos}--;
            }
            $self->checkValid( !!1 );
          } #/ if ( $self->{curPos} >...)
          last;
        };
        kbDel == $_ and do {
          if ( $self->{selStart} == $self->{selEnd} ) {
            if ( $self->{curPos} < length( $self->{data} ) ) {
              $self->{selStart} = $self->{curPos};
              $self->{selEnd}   = $self->{curPos} + 1;
            }
          }
          $self->deleteSelect();
          $self->checkValid( !!1 );
          last;
        };
        kbIns == $_ and do {
          $self->setState( sfCursorIns, !( $self->{state} & sfCursorIns ) );
          last;
        };
        DEFAULT: {
          my $ch = $event->{keyDown}{charScan}{charCode};
          if ( defined $ch && $ch >= ord( ' ' ) ) {
            $self->deleteSelect();
            if ( $self->{state} & sfCursorIns ) {
              # The following must be a signed comparison!
              if ( $self->{curPos} < length( $self->{data} ) ) {
                substr( $self->{data}, $self->{curPos}, 1, '' );
              }
            }
            if ( $self->checkValid( !!1 ) ) {
              if ( length( $self->{data} ) < $self->{maxLen} ) {
                if ( $self->{firstPos} > $self->{curPos} ) {
                  $self->{firstPos} = $self->{curPos};
                }
                substr( $self->{data}, $self->{curPos} + 1 ) =
                  substr( $self->{data}, $self->{curPos} );
                substr( $self->{data}, $self->{curPos}, 1 ) = chr( $ch );
                $self->{curPos}++;
              }
              $self->checkValid( !!0 );
            } #/ if ( $self->checkValid...)
          } #/ if ( defined $ch && $ch...)
          elsif ( defined $ch && $ch == CONTROL_Y ) {
            $self->{data}   = '';
            $self->{curPos} = 0;
          }
          else {
            return;
          }
          last;
        };
      } #/: for ( $event->{keyDown}...)

      $self->adjustSelectBlock();
      if ( $self->{firstPos} > $self->{curPos} ) {
        $self->{firstPos} = $self->{curPos};
      }
      $i = $self->{curPos} - $self->{size}{x} + 2;
      if ( $self->{firstPos} < $i ) {
        $self->{firstPos} = $i;
      }
      $self->drawView();
      $self->clearEvent( $event );
      last;
    };
  } #/ SWITCH: for ( $event->{what} )
  return;
} #/ sub handleEvent

sub selectAll {    # void ($enable)
  my ( $self, $enable ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( !defined $enable or !ref $enable);
  $self->{selStart} = 0;
  if ( $enable ) {
    my $len = length( $self->{data} );
    $self->{curPos} = $self->{selEnd} = $len;
  }
  else {
    $self->{curPos} = $self->{selEnd} = 0;
  }
  $self->{firstPos} = max( 0, $self->{curPos} - $self->{size}{x} + 2 );
  $self->{anchor} = 0;    # This sets anchor to avoid deselect on init selection
  $self->drawView();
  return;
} #/ sub selectAll

sub setData {    # void (\@rec)
  my ( $self, $rec ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( ref $rec );
  if ( !$self->{validator}
    || !$self->{validator}->transfer( $self->{data}, $rec, vtSetData ) )
  {
    assert ( $self->dataSize() );
    assert ( defined $rec->[0] and !ref $rec->[0] );
    $self->{data} = substr( $rec->[0], 0, $self->{maxLen} );
  } #/ if ( !$self->{validator...})
  $self->selectAll( !!1 );
  return;
} #/ sub setData

sub setState {    # void ($aState, $enable)
  my ( $self, $aState, $enable ) = @_;
  assert ( @_ == 3 );
  assert ( blessed $self );
  assert ( looks_like_number $aState );
  assert ( !defined $enable or !ref $enable );
  $self->SUPER::setState( $aState, $enable );
  if ( $aState == sfSelected
    || ( $aState == sfActive && ( $self->{state} & sfSelected ) ) )
  {
    $self->selectAll( $enable );
  }
  return;
} #/ sub setState

sub setValidator {    # void ($aValid|undef)
  my ( $self, $aValid ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( !defined or blessed $aValid );
  if ( $self->{validator} ) {
    $self->destroy( $self->{validator} );
  }
  $self->{validator} = $aValid;
  return;
} #/ sub setValidator

sub canScroll {    # bool ($delta)
  my ( $self, $delta ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( looks_like_number $delta );
  if ( $delta < 0 ) {
    return $self->{firstPos} > 0;
  }
  elsif ( $delta > 0 ) {
    return length( $self->{data} ) - $self->{firstPos} + 2 > $self->{size}{x};
  }
  else {
    return !!0;
  }
} #/ sub canScroll

sub mouseDelta {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( blessed $event );
  my $mouse = $self->makeLocal( $event->{mouse}{where} );

  if ( $mouse->{x} <= 0 ) {
    return -1;
  }
  else {
    $mouse->{x} >= $self->{size}{x} - 1 ? 1 : 0;
  }
} #/ sub mouseDelta

sub mousePos {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( blessed $event );
  my $mouse = $self->makeLocal( $event->{mouse}{where} );
  $mouse->{x} = max( $mouse->{x}, 1 );
  my $pos = $mouse->{x} + $self->{firstPos} - 1;
  $pos = max( $pos, 0 );
  $pos = min( $pos, length( $self->{data} ) );
  return $pos;
} #/ sub mousePos

sub deleteSelect {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  if ( $self->{selStart} < $self->{selEnd} ) {
    substr( $self->{data}, $self->{selStart} ) =
      substr( $self->{data}, $self->{selEnd} );
    $self->{curPos} = $self->{selStart};
  } #/ if ( $self->{selStart}...)
  return;
} #/ sub deleteSelect

sub adjustSelectBlock {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  if ( $self->{anchor} < 0 ) {
    $self->{selStart} = 0;
    $self->{selEnd}   = 0;
  }
  elsif ( $self->{anchor} > $self->{curPos} ) {
    $self->{selStart} = $self->{curPos};
    $self->{selEnd}   = $self->{anchor};
  }
  else {
    $self->{selStart} = $self->{anchor};
    $self->{selEnd}   = $self->{curPos};
  }
  return;
} #/ sub adjustSelectBlock

sub saveState {   # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  if ( $self->{validator} ) {
    $self->{oldData}     = $self->{data};
    $self->{oldCurPos}   = $self->{curPos};
    $self->{oldFirstPos} = $self->{firstPos};
    $self->{oldSelStart} = $self->{selStart};
    $self->{oldSelEnd}   = $self->{selEnd};
    $self->{oldAnchor}   = $self->{anchor};
  } #/ if ( $self->{validator...})
  return;
} #/ sub saveState

sub restoreState {   # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  if ( $self->{validator} ) {
    $self->{data}     = $self->{oldData};
    $self->{curPos}   = $self->{oldCurPos};
    $self->{firstPos} = $self->{oldFirstPos};
    $self->{selStart} = $self->{oldSelStart};
    $self->{selEnd}   = $self->{oldSelEnd};
    $self->{anchor}   = $self->{oldAnchor};
  } #/ if ( $self->{validator...})
  return;
} #/ sub restoreState

sub checkValid {   # $bool ($noAutoFill)
  my ( $self, $noAutoFill ) = @_;
  assert ( blessed $self );
  assert ( !defined $noAutoFill or !ref $noAutoFill );
  return !!1 unless $self->{validator};
  my $oldLen = length( $self->{data} );
  my $newData = $self->{data};
  if ( !$self->{validator}->isValidInput( $newData, $noAutoFill ) ) {
    $self->restoreState();
    return !!0;
  }
  else {
    if ( length( $newData ) > $self->{maxLen} ) {
      substr( $newData, $self->{maxLen} ) = '';
    }
    $self->{data} = $newData;
    if ( $self->{curPos} >= $oldLen && length( $self->{data} ) > $oldLen ) {
      $self->{curPos} = length( $self->{data} );
    }
    return !!1;
  } #/ else [ if ( !$self->{validator...})]
} #/ sub checkValid

1
