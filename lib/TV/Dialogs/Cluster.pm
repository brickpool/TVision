package TV::Dialogs::Cluster;
# ABSTRACT: Cluster base control (check/radio style) for Turbo Vision

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT = qw(
  TCluster
  new_TCluster
);

use TV::toolkit;
use TV::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TV::Dialogs::Const qw( cpCluster );
use TV::Dialogs::Util qw( hotKey );
use TV::Drivers::Const qw(
  :evXXXX
  kbUp
  kbDown
  kbLeft
  kbRight
);
use TV::Drivers::Util qw(
  cstrlen
  ctrlToArrow
  getAltCode
);
use TV::Objects::StringCollection;
use TV::Views::Const qw(
  hcNoContext
  :ofXXXX
  phPostProcess
  :sfXXXX
);
use TV::Views::DrawBuffer;
use TV::Views::Palette;
use TV::Views::View;

sub TCluster() { __PACKAGE__ }
sub name() { 'TCluster' }
sub new_TCluster { __PACKAGE__->from(@_) }

extends TView;

# import global variables
use vars qw(
  $showMarkers
  $specialChars
);
{
  no strict 'refs';
  *showMarkers  = \${ TView . '::showMarkers' };
  *specialChars = \${ TView . '::specialChars' };
}

# protected attributes
has value      => ( is => 'ro', default => 0 );
has enableMask => ( is => 'ro', default => 0xffff_ffff );
has sel        => ( is => 'ro', default => 0 );
has strings    => ( is => 'ro', default => sub { die 'required' } );

# predeclare private methods
my (
  $column,
  $findSel,
  $row,
  $moveSel,
);

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      bounds  => Object,
      strings => Maybe[HashLike], { alias => 'aStrings' },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  my $aStrings = $self->{strings};

  $self->{options} = ofSelectable | ofFirstClick | ofPreProcess | ofPostProcess;
  my $i = 0;
  my $p;
  for ( my $p = $aStrings ; $p ; $p = $p->{next} ) {
    $i++;
  }

  $self->{strings} = new_TStringCollection( $i, 0 );

  while ( $aStrings ) {
    $p = $aStrings;
    $self->{strings}->atInsert(
      $self->{strings}->getCount(),
      $aStrings->{value}
    );
    $aStrings = $aStrings->{next};
    $p->{next} = undef;
  }

  $self->setCursor( 2, 0 );
  $self->showCursor();
  return;
} #/ sub BUILD

sub from {    # $obj ($bounds, $aStrings|undef)
  state $sig = signature(
    method => 1,
    pos    => [Object, Maybe[HashLike]],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], strings => $args[1] );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{strings} = undef;
  return;
} #/ sub DEMOLISH

sub dataSize {    # $size ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  $sig->( @_ );
  return 1;
}

sub drawBox {    # void ($icon, $marker)
  state $sig = signature(
    method => Object,
    pos    => [Str, Str],
  );
  my ( $self, $icon, $marker ) = $sig->( @_ );
  my $s = ' ' . substr( $marker, 0, 1 );
  $self->drawMultiBox( $icon, $s );
  return;
} #/ sub drawBox

sub drawMultiBox {    # void ($icon, $marker)
  state $sig = signature(
    method => Object,
    pos    => [Str, Str],
  );
  my ( $self, $icon, $marker ) = $sig->( @_ );

  my $b = TDrawBuffer->new();
  my $color;
  my ( $i, $j, $cur );

  my $cNorm = $self->getColor( 0x0301 );
  my $cSel  = $self->getColor( 0x0402 );
  my $cDis  = $self->getColor( 0x0505 );
  for ( $i = 0 ; $i <= $self->{size}{y} ; $i++ ) {
    $b->moveChar( 0, ' ', $cNorm, $self->{size}{x} );
    my $n = int( ( $self->{strings}->getCount() - 1 ) / $self->{size}{y} ) + 1;
    for ( $j = 0 ; $j <= $n ; $j++ ) {
      my $cur = $j * $self->{size}{y} + $i;
      next if $cur >= $self->{strings}->getCount();

      my $col = $self->$column( $cur );

      next if $col >= $self->{size}{x};

      if ( !$self->buttonState( $cur ) ) {
        $color = $cDis;
      }
      elsif ( $cur == $self->{sel}
        && ( $self->{state} & sfSelected ) )
      {
        $color = $cSel;
      }
      else {
        $color = $cNorm;
      }
      $b->moveChar( $col, ' ', $color, $self->{size}{x} - $col );
      $b->moveCStr( $col, $icon, $color );

      $b->putChar( $col + 2, substr( $marker, $self->multiMark( $cur ), 1 ) );
      $b->moveCStr( $col + 5, $self->{strings}->at( $cur ), $color );
      if ( $showMarkers
        && ( $self->{state} & sfSelected )
        && $cur == $self->{sel}
      ) {
        $b->putChar( $col, $specialChars->[0] );
        $b->putChar( $self->$column( $cur + $self->{size}{y} ) - 1, 
          $specialChars->[1] );
      }
    } #/ for ( my $j = 0 ; $j <=...)
    $self->writeBuf( 0, $i, $self->{size}{x}, 1, $b );
  } #/ for ( my $i = 0 ; $i <=...)
  $self->setCursor(
    $self->$column( $self->{sel} ) + 2,
    $self->$row( $self->{sel} ),
  );
  return;
} #/ sub drawMultiBox

sub getData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  my ( $self, $rec ) = $sig->( @_ );
  $rec->[0] = $self->{value};
  $self->drawView();
  return;
} #/ sub getData

sub getHelpCtx {    # $ctx ()
  no warnings 'uninitialized';
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return $self->{helpCtx} == hcNoContext
    ? hcNoContext
    : $self->{helpCtx} + $self->{sel};
} #/ sub getHelpCtx

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cpCluster, 
    size => length( cpCluster )
  );
  return $palette->clone;
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );

  $self->SUPER::handleEvent( $event );
  return unless $self->{options} & ofSelectable;
  if ( $event->{what} == evMouseDown ) {
    my $mouse = $self->makeLocal( $event->{mouse}{where} );
    my $i     = $self->$findSel( $mouse );
    if ( $i != -1 && $self->buttonState( $i ) ) {
      $self->{sel} = $i;
    }
    $self->drawView();
    do {
      $mouse = $self->makeLocal( $event->{mouse}{where} );
      if ( $self->$findSel( $mouse ) == $self->{sel}
        && $self->buttonState( $self->{sel} )
      ) {
        $self->showCursor();
      }
      else {
        $self->hideCursor();
      }
    } while $self->mouseEvent( $event, evMouseMove );
    $self->showCursor;
    $mouse = $self->makeLocal( $event->{mouse}{where} );
    if ( $self->$findSel( $mouse ) == $self->{sel} ) {
      $self->press( $self->{sel} );
      $self->drawView();
    }
    $self->clearEvent( $event );
  }
  elsif ( $event->{what} == evKeyDown ) {
    my $s = $self->{sel};
    SWITCH: for ( ctrlToArrow( $event->{keyDown}{keyCode} ) ) {

      kbUp == $_ and do {
        if ( $self->{state} & sfFocused ) {
          my $i = 0;
          do {
            $i++; $s--;
            $s = $self->{strings}->getCount() - 1 if $s < 0;
          } while ( !$self->buttonState( $s ) 
                  || $i > $self->{strings}->getCount() );
          $self->$moveSel( $i, $s );
          $self->clearEvent( $event );
        } #/ if ( $self->{state} & ...)
        last;
      };

      kbDown == $_ and do {
        if ( $self->{state} & sfFocused ) {
          my $i = 0;
          do {
            $i++; $s++;
            $s = 0 if $s >= $self->{strings}->getCount();
          } while ( !$self->buttonState( $s ) 
                  || $i > $self->{strings}->getCount() );
          $self->$moveSel( $i, $s );
          $self->clearEvent( $event );
        } #/ if ( $self->{state} & ...)
        last;
      };

      kbRight == $_ and do {
        if ( $self->{state} & sfFocused ) {
          my $i = 0;
          do {
            $i++;
            $s += $self->{size}{y};
            # BUG FIX - EFW - 10/25/94
            if ( $s >= $self->{strings}->getCount() ) {
              $s = ( ( $s + 1 ) % $self->{size}{y} );
              $s = 0 if $s >= $self->{strings}->getCount();
            }
          } while ( !$self->buttonState( $s ) 
                  || $i > $self->{strings}->getCount() );
          $self->$moveSel( $i, $s );    # BUG FIX - EFW - 10/25/94
          $self->clearEvent( $event );
        } #/ if ( $self->{state} & ...)
        last;
      };

      kbLeft == $_ and do {
        if ( $self->{state} & sfFocused ) {
          my $i = 0;
          do {
            $i++;
            if ( $s > 0 ) {
              $s -= $self->{size}{y};
              if ( $s < 0 ) {
                $s = ( ( $self->{strings}->getCount() + $self->{size}{y} - 1 ) /
                  $self->{size}{y} ) * $self->{size}{y} + $s - 1;
                $s = $self->{strings}->getCount() - 1
                  if $s >= $self->{strings}->getCount();
              }
            }
            else {
              $s = $self->{strings}->getCount() - 1;
            }
          } while ( !$self->buttonState( $s ) 
                  || $i > $self->{strings}->getCount() );
          $self->$moveSel( $i, $s );    # BUG FIX - EFW - 10/25/94
          $self->clearEvent( $event );
        } #/ if ( $self->{state} & ...)
        last;
      };

      DEFAULT: {
        for ( my $i = 0 ; $i < $self->{strings}->getCount() ; $i++ ) {
          my $c = hotKey( $self->{strings}->at($i) );
          if (
            getAltCode( $c ) == $event->{keyDown}{keyCode} ||
            ( ( $self->{owner}{phase} == phPostProcess || 
                ( $self->{state} & sfFocused )
              ) && 
              $c && 
              uc( chr $event->{keyDown}{charScan}{charCode} ) eq uc( $c )
            )
          ) {
            if ( $self->buttonState( $i ) ) {
              if ( $self->focus() ) {
                $self->{sel} = $i;
                $self->movedTo( $self->{sel} );
                $self->press( $self->{sel} );
                $self->drawView();
              }
              $self->clearEvent( $event );
            }
            return;
          } #/ if ( getAltCode( $c ) ...)
        } #/ for ( my $i = 0 ; $i < ...)

        if ( $event->{keyDown}{charScan}{charCode} == ord( ' ' )
          && ( $self->{state} & sfFocused )
        ) {
          $self->press( $self->{sel} );
          $self->drawView();
          $self->clearEvent( $event );
        }
      };
    } #/ SWITCH: for ( $event->{keyDown}...)
  }
  return;
} #/ sub handleEvent

sub mark {    # $bool ($item)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $item ) = $sig->( @_ );
  return false;
}

sub multiMark {    # $int ($item)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $item ) = $sig->( @_ );
  return $self->mark( $item ) ? 1 : 0;
}

sub press {    # void ($item)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $item ) = $sig->( @_ );
  return;
}

sub movedTo {    # void ($item)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $item ) = $sig->( @_ );
  return;
}

sub setData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  my ( $self, $rec ) = $sig->( @_ );
  $self->{value} = 0+ $rec->[0];
  $self->drawView();
  return;
} #/ sub setData

sub setState {    # void ($aState, $enable)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Bool],
  );
  my ( $self, $aState, $enable ) = $sig->( @_ );
  $self->SUPER::setState( $aState, $enable );
  if ( $aState == sfSelected ) {
    my $i = 0;
    my $s = $self->{sel} - 1;
    do {
      $i++;
      $s++;
      $s = 0 
        if $s >= $self->{strings}->getCount();
    } while ( !$self->buttonState( $s ) || $i > $self->{strings}->getCount() );

    $self->$moveSel( $i, $s );
  } #/ if ( $aState == sfSelected)

  $self->drawView();
  return;
} #/ sub setState

sub setButtonState {    # void ($aMask, $enable)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Bool],
  );
  my ( $self, $aMask, $enable ) = $sig->( @_ );
  if ( !$enable ) {
    $self->{enableMask} &= ~$aMask;
  }
  else {
    $self->{enableMask} |= $aMask;
  }

  my $n = $self->{strings}->getCount();
  if ( $n < 32 ) {
    my $testMask = ( 1 << $n ) - 1;
    if ( $self->{enableMask} & $testMask ) {
      $self->{options} |= ofSelectable;
    }
    else {
      $self->{options} &= ~ofSelectable;
    }
  }
  return;
} #/ sub setButtonState

$column = sub {    # $col ($item)
  my ( $self, $item ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Int $item );
  if ( $item < $self->{size}{y} ) {
    return 0;
  }
  else {
    my $width = 0;
    my $col   = -6;
    my $l     = 0;
    for ( my $i = 0 ; $i <= $item ; $i++ ) {
      if ( $i % $self->{size}{y} == 0 ) {
        $col += $width + 6;
        $width = 0;
      }
      if ( $i < $self->{strings}->getCount() ) {
        $l = cstrlen( $self->{strings}->at( $i ) );
      }
      $width = $l
        if $l > $width;
    } #/ for ( my $i = 0 ; $i <=...)
    return $col;
  } #/ else [ if ( $item < $self->{size}{y} ) ]
};

$findSel = sub {    # $index ($p)
  my ( $self, $p ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Object $p );
  my $r = $self->getExtent();
  if ( !$r->contains( $p ) ) {
    return -1;
  }
  else {
    my $i = 0;
    while ( $p->{x} >= $self->$column( $i + $self->{size}{y} ) ) {
      $i += $self->{size}{y};
    }
    my $s = $i + $p->{y};
    return $s >= $self->{strings}->getCount()
      ? -1 
      : $s;
  }
};

$row = sub {    # $row ($item)
  my ( $self, $item ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Int $item );
  return $item % $self->{size}{y};
};

$moveSel = sub {    # void ($i, $s)
  my ( $self, $i, $s ) = @_;
  assert ( @_ == 3 );
  assert ( is_Object $self );
  assert ( is_Int $i );
  assert ( is_Int $s );
  if ( $i <= $self->{strings}->getCount() ) {
    $self->{sel} = $s;
    $self->movedTo( $self->{sel} );
    $self->drawView();
  }
  return;
};

sub buttonState {    # $bool ($item)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $item ) = $sig->( @_ );
  return false if $item < 0 || $item >= 32;
  my $mask = ( 1 << $item );
  return !!( $self->{enableMask} & $mask );
} #/ sub buttonState

1

__END__

=pod

=head1 NAME

TCluster - base control class for TRadioButtons, TCheckBoxes etc.

=head1 DESCRIPTION

C<TCluster> provides the common base implementation for all cluster-style input 
controls.  It manages selection, navigation, enable-masks and visual 
representation of clustered items.  

The class handles both keyboard and mouse input to navigate and activate 
individual entries. Subclasses override the marking and activation behavior to 
implement specific cluster types.

=head1 ATTRIBUTES

=over

=item value

Holds the numeric value associated with the current selection state (I<Int>).

=item enableMask

Bitmask indicating which items are enabled and selectable (I<Int>).

=item sel

Index of the currently selected item inside the cluster (I<Int>).

=item strings

Collection containing the text labels of all cluster items (I<TSItem>).

=back

=head1 METHODS

=head2 new

 my $cluster = TCluster->new(%args);

Creates a new cluster with given bounds and item list.

=over

=item bounds

Defines the screen rectangle (I<TRect>) specifying the position and size of the 
cluster control.

=item strings

Provides the linked list of item descriptors (I<TSItem>) that are consumed and 
converted into an internal string collection.

=back

=head2 new_TCluster

 my $cluster = new_TCluster($bounds, $aStrings | undef);

Constructs a new cluster instance using the Turbo Vision factory wrapper.

=head2 buttonState

 my $bool = $self->buttonState($item);

Returns true if the specified item is enabled according to the enableMask.

=head2 dataSize

 my $size = $self->dataSize();

Returns the number of scalars transferred via getData/setData.

=head2 drawBox

 $self->drawBox($icon, $marker);

Draws a single selection box with the given icon and marker.

=head2 drawMultiBox

 $self->drawMultiBox($icon, $marker);

Renders the full multi-column cluster layout.

=head2 getData

 $self->getData(\@rec);

Stores the cluster's current value into the supplied record.

=head2 getHelpCtx

 my $ctx = $self->getHelpCtx();

Returns the help context offset by the current selection.

=head2 getPalette

 my $palette = $self->getPalette();

Returns a cloned palette used for rendering cluster elements.

=head2 handleEvent

 $self->handleEvent($event);

Processes keyboard and mouse events for navigation and activation.

=head2 mark

 my $bool = $self->mark($item);

Indicates whether the given item is marked; subclasses override this.

=head2 movedTo

 $self->movedTo($item);

Called whenever the selection moves to another item.

=head2 multiMark

 my $int = $self->multiMark($item);

Returns the marker index (0 or 1) depending on mark().

=head2 press

 $self->press($item);

Invoked when an item is activated; subclasses implement their behavior.

=head2 setButtonState

 $self->setButtonState($aMask, $enable);

Enables or disables items using a bitmask and updates cluster selectability.

=head2 setData

 $self->setData(\@rec);

Applies the stored value from an external record.

=head2 setState

 $self->setState($aState, $enable);

Handles state changes and moves the selection if required.

=head1 AUTHORS

=over

=item Turbo Vision Development Team

=item J. Schneider <brickpool@cpan.org>

=back

=head1 CONTRIBUTORS

=over

=item Eric Woodruff

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 1994, 2026 the L</AUTHORS> and L</CONTRIBUTORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution). 

=cut
