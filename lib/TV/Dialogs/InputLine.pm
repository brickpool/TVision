package TV::Dialogs::InputLine;
# ABSTRACT: Editable single-line text input control for Turbo Vision dialogs.

use 5.010;
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

use List::Util qw( min max );
use PerlX::Assert::PP;
use TV::toolkit;
use TV::toolkit::Params qw( signature );
use TV::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TV::Const qw( EOS );
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

sub TInputLine() { __PACKAGE__ }
sub name() { 'TInputLine' }
sub new_TInputLine { __PACKAGE__->from(@_) }

extends TView;

use constant CONTROL_Y => 25;

# declare global variables
our $rightArrow = "\x10";
our $leftArrow  = "\x11";

# public attributes
has data        => ( is => 'rw', default => '' );
has maxLen      => ( is => 'ro', default => sub { die 'required' } );
has curPos      => ( is => 'rw', default => 0 );
has firstPos    => ( is => 'rw', default => 0 );
has selStart    => ( is => 'ro', default => 0 );
has selEnd      => ( is => 'ro', default => 0 );

# private attributes
has validator   => ( is => 'bare' );
has anchor      => ( is => 'bare', default => -1 );
has oldAnchor   => ( is => 'bare', default => -1 );    # New to save state info
has oldData     => ( is => 'bare', default => '' );
has oldCurPos   => ( is => 'bare' );
has oldFirstPos => ( is => 'bare' );
has oldSelStart => ( is => 'bare' );
has oldSelEnd   => ( is => 'bare' );

# predeclare private methods
my (
  $canScroll,
  $mouseDelta,
  $mousePos,
  $deleteSelect,
  $adjustSelectBlock,
  $saveState,
  $restoreState,
  $checkValid,
);

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      bounds    => Object,
      maxLen    => Int,    { alias => 'aMaxLen' },
      validator => Object, { alias => 'aValid', optional => 1 },
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
  $self->{state} |= sfCursorVis;
  $self->{options} |= ofSelectable | ofFirstClick;
  return;
}

sub from {    # $obj ($bounds, $aMaxLen, |$aValid)
  state $sig = signature(
    method => 1,
    pos    => [
      Object,
      Int,
      Object, { optional => 1 }
    ],
  );
  my ( $class, @args ) = $sig->( @_ );
  SWITCH: for ( scalar @args ) {
    $_ == 2 and return $class->new( bounds => $args[0], maxLen => $args[1] );
    $_ == 3 and return $class->new( bounds => $args[0], maxLen => $args[1], 
      validator => $args[2] );
  }
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{data} = undef;
  $self->{oldData} = undef;
  $self->destroy( $self->{validator} );
  return;
}

sub dataSize {    # $dSize ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
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
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  my ( $l, $r );
  my $b = TDrawBuffer->new();
  my $color = $self->{state} & sfFocused
            ? $self->getColor( 2 )
            : $self->getColor( 1 );

  $b->moveChar( 0, ' ', $color, $self->{size}{x} );
  my $buf = substr( $self->{data}, $self->{firstPos}, $self->{size}{x} - 2 );
  $b->moveStr( 1, $buf, $color );

  if ( $self->$canScroll( 1 ) ) {
    $b->moveChar( $self->{size}{x} - 1, $rightArrow, $self->getColor( 4 ), 1 );
  }
  if ( $self->{state} & sfSelected ) {
    if ( $self->$canScroll( -1 ) ) {
      $b->moveChar( 0, $leftArrow, $self->getColor( 4 ), 1 );
    }
    $l = $self->{selStart} - $self->{firstPos};
    $r = $self->{selEnd} - $self->{firstPos};
    $l = max( 0, $l );
    $r = min( $self->{size}{x} - 2, $r );
    if ( $l < $r ) {
      $b->moveChar( $l + 1, 0, $self->getColor( 3 ), $r - $l );
    }
  } #/ if ( ( $self->{state} ...))
  $self->writeLine( 0, 0, $self->{size}{x}, $self->{size}{y}, $b );
  $self->setCursor( $self->{curPos} - $self->{firstPos} + 1, 0 );
  return;
} #/ sub draw

sub getData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  my ( $self, $rec ) = $sig->( @_ );
  if ( !$self->{validator}
    || !$self->{validator}->transfer( $self->{data}, $rec, vtGetData )
  ) {
    assert ( $self->dataSize() );
    $rec->[0] = $self->{data};
  }
  return;
} #/ sub getData

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cpInputLine, 
    size => length( cpInputLine ),
  );
  return $palette->clone();
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  # Home, Left Arrow, Right Arrow, End, Ctrl-Left Arrow, Ctrl-Right Arrow
  my @padKeys = ( 0x47, 0x4b, 0x4d, 0x4f, 0x73, 0x74 );
  $self->SUPER::handleEvent( $event );

  my ( $delta, $i );
  return unless ( $self->{state} & sfSelected );
  SWITCH: for ( $event->{what} ) {
    evMouseDown == $_ and do {
      if ( $self->$canScroll( $delta = $self->$mouseDelta( $event ) ) ) {
        do {
          if ( $self->$canScroll( $delta ) ) {
            $self->{firstPos} += $delta;
            $self->drawView();
          }
        } while $self->mouseEvent( $event, evMouseAuto );
      } #/ if ( $self->$canScroll(...))
      elsif ( $event->{mouse}{eventFlags} & meDoubleClick ) {
        $self->selectAll( 1 );
      }
      else {
        $self->{anchor} = $self->$mousePos( $event );
        do {
          if ( $event->{what} == evMouseAuto ) {
            $delta = $self->$mouseDelta( $event );
            if ( $self->$canScroll( $delta ) ) {
              $self->{firstPos} += $delta;
            }
          }
          $self->{curPos} = $self->$mousePos( $event );
          $self->$adjustSelectBlock();
          $self->drawView();
        } while $self->mouseEvent( $event, evMouseMove | evMouseAuto );
      } #/ else [ if ( $self->$canScroll(...))]
      $self->clearEvent( $event );
      last;
    };

    evKeyDown == $_ and do {
      $self->$saveState();
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
            $self->$checkValid( !!1 );
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
          $self->$deleteSelect();
          $self->$checkValid( !!1 );
          last;
        };
        kbIns == $_ and do {
          $self->setState( sfCursorIns, !( $self->{state} & sfCursorIns ) );
          last;
        };
        DEFAULT: {
          my $ch = $event->{keyDown}{charScan}{charCode};
          if ( defined $ch && $ch >= ord( ' ' ) ) {
            $self->$deleteSelect();
            if ( $self->{state} & sfCursorIns ) {
              # The following is always a signed comparison in Perl!
              if ( $self->{curPos} < length( $self->{data} ) ) {
                substr( $self->{data}, $self->{curPos}, 1, '' );
              }
            }
            if ( $self->$checkValid( !!1 ) ) {
              my $strlen = length( $self->{data} );
              if ( $strlen < $self->{maxLen} ) {
                if ( $self->{firstPos} > $self->{curPos} ) {
                  $self->{firstPos} = $self->{curPos};
                }
                # In Perl, only move the data if the insertion is not at end
                if ( $self->{curPos} < $strlen ) {
                  substr( $self->{data}, $self->{curPos} + 1 ) =
                    substr( $self->{data}, $self->{curPos} )
                }
                substr( $self->{data}, $self->{curPos}, 1 ) = chr( $ch );
                $self->{curPos}++;
              }
              $self->$checkValid( !!0 );
            } #/ if ( $self->$checkValid...)
          } #/ if ( defined $ch && $ch...)
          elsif ( defined $ch && $ch == CONTROL_Y ) {
            $self->{data}   = EOS;
            $self->{curPos} = 0;
          }
          else {
            return;
          }
          last;
        };
      } #/ SWITCH: for ( $event->{keyDown}...)

      $self->$adjustSelectBlock();
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
  state $sig = signature(
    method => Object,
    pos    => [Bool],
  );
  my ( $self, $enable ) = $sig->( @_ );
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
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  my ( $self, $rec ) = $sig->( @_ );
  if ( !$self->{validator}
    || !$self->{validator}->transfer( $self->{data}, $rec, vtSetData )
  ) {
    assert ( $self->dataSize() );
    assert ( defined $rec->[0] and !ref $rec->[0] );
    $self->{data} = substr( $rec->[0], 0, $self->{maxLen} );
  } #/ if ( !$self->{validator...})
  $self->selectAll( !!1 );
  return;
} #/ sub setData

sub setState {    # void ($aState, $enable)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Bool],
  );
  my ( $self, $aState, $enable ) = $sig->( @_ );
  $self->SUPER::setState( $aState, $enable );
  if ( $aState == sfSelected
    || ( $aState == sfActive && ( $self->{state} & sfSelected ) )
  ) {
    $self->selectAll( $enable );
  }
  return;
} #/ sub setState

sub setValidator {    # void ($aValid|undef)
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Object]],
  );
  my ( $self, $aValid ) = $sig->( @_ );
  if ( $self->{validator} ) {
    $self->destroy( $self->{validator} );
  }
  $self->{validator} = $aValid;
  return;
} #/ sub setValidator

$canScroll = sub {    # bool ($delta)
  my ( $self, $delta ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Int $delta );
  if ( $delta < 0 ) {
    return $self->{firstPos} > 0;
  }
  elsif ( $delta > 0 ) {
    return length( $self->{data} ) - $self->{firstPos} + 2 > $self->{size}{x};
  }
  else {
    return !!0;
  }
};

$mouseDelta = sub {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Object $event );
  my $mouse = $self->makeLocal( $event->{mouse}{where} );

  if ( $mouse->{x} <= 0 ) {
    return -1;
  }
  else {
    $mouse->{x} >= $self->{size}{x} - 1 ? 1 : 0;
  }
};

$mousePos = sub {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Object $event );
  my $mouse = $self->makeLocal( $event->{mouse}{where} );
  $mouse->{x} = max( $mouse->{x}, 1 );
  my $pos = $mouse->{x} + $self->{firstPos} - 1;
  $pos = max( $pos, 0 );
  $pos = min( $pos, length( $self->{data} ) );
  return $pos;
};

$deleteSelect = sub {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  if ( $self->{selStart} < $self->{selEnd} ) {
    substr( $self->{data}, $self->{selStart} ) =
      substr( $self->{data}, $self->{selEnd} );
    $self->{curPos} = $self->{selStart};
  } #/ if ( $self->{selStart}...)
  return;
};

$adjustSelectBlock = sub {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
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
};

$saveState = sub {   # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  if ( $self->{validator} ) {
    $self->{oldData}     = $self->{data};
    $self->{oldCurPos}   = $self->{curPos};
    $self->{oldFirstPos} = $self->{firstPos};
    $self->{oldSelStart} = $self->{selStart};
    $self->{oldSelEnd}   = $self->{selEnd};
    $self->{oldAnchor}   = $self->{anchor};
  } #/ if ( $self->{validator...})
  return;
};

$restoreState = sub {   # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  if ( $self->{validator} ) {
    $self->{data}     = $self->{oldData};
    $self->{curPos}   = $self->{oldCurPos};
    $self->{firstPos} = $self->{oldFirstPos};
    $self->{selStart} = $self->{oldSelStart};
    $self->{selEnd}   = $self->{oldSelEnd};
    $self->{anchor}   = $self->{oldAnchor};
  } #/ if ( $self->{validator...})
  return;
};

$checkValid = sub {   # $bool ($noAutoFill)
  my ( $self, $noAutoFill ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Bool $noAutoFill );
  return !!1 unless $self->{validator};
  my $oldLen = length( $self->{data} );
  my $newData = $self->{data};
  if ( !$self->{validator}->isValidInput( $newData, $noAutoFill ) ) {
    $self->$restoreState();
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
};

1

__END__

=pod

=head1 NAME

TInputLine - editable single-line text input control for Turbo Vision dialogs

=head1 SYNOPSIS

  use TV::Dialogs::InputLine;

  my $input = new_TInputLine($bounds, 64);
  $input->setData(["Hello"]);

=head1 DESCRIPTION

C<TInputLine> provides an editable text field with cursor control, selection, 
and validation support. It handles keyboard input, mouse selection, scrolling, 
and optional validators. It is intended for use wherever a single editable text 
field is required.

=head1 ATTRIBUTES

=over

=item data

The current input string stored inside the control (I<Str>).

=item maxLen

Maximum allowed length of the input text (I<Int>).

=item curPos

The current cursor position within the input string (I<Int>).

=item firstPos

The index of the first visible character, used for horizontal scrolling 
(I<Int>).

=item selStart

The start index of the current selection block (I<Int>).

=item selEnd

The end index of the current selection block (I<Int>).

=item validator

Optional validator object used for input checking and data transfer 
(I<TValidator> or undef).

=item anchor

Selection anchor used during mouse or shift-key selection (I<Int>).

=item oldAnchor

Stored anchor position for validation rollback (I<Int>).

=item oldData

Cached input data used to restore previous state after failed validation 
(I<Str>).

=item oldCurPos

Previous cursor position saved before validation attempts (I<Int>).

=item oldFirstPos

Previous visible offset saved before validation attempts (I<Int>).

=item oldSelStart

Previous selection start stored for validation rollback (I<Int>).

=item oldSelEnd

Previous selection end stored for validation rollback (I<Int>).

=back

=head1 METHODS

=head2 new

  my $input = TInputLine->new(%args);

Creates a new input line with the given bounds and maximum allowed text length.

=over

=item bounds

The rectangular position and size of the input line (I<TRect>).

=item maxLen

The maximum number of characters the input field can hold (integer).

=item validator

An optional validator object used for input checking (I<TValidator> or undef).

=back

=head2 new_TInputLine

  my $input = new_TInputLine($bounds, $aMaxLen, | $aValid);

Factory constructor that builds an input line control from C<$bounds>, length 
and optional validator.

=head2 dataSize

 my $dSize = $self->dataSize();

Returns the size required to store the control's data based on its validator.

=head2 draw

 $self->draw();

Displays the current text, cursor position and selection region.

=head2 getData

 $self->getData(\@rec);

Transfers the control's text content into the provided record structure.

=head2 getPalette

 my $palette = $self->getPalette();

Returns the palette used for drawing the input line.

=head2 handleEvent

 $self->handleEvent($event);

Processes keyboard navigation, editing commands, scrolling and mouse input.

=head2 selectAll

 $self->selectAll($enable);

Selects or clears all text based on the given argument.

=head2 setData

 $self->setData(\@rec);

Replaces the control's text content using a record structure.

=head2 setState

 $self->setState($aState, $enable);

Updates internal state flags and adjusts selection and cursor behavior.

=head2 setValidator

 $self->setValidator($aValid | undef);

Installs or replaces the validator object for input checking.

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
