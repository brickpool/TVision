=pod

=head1 NAME

TV::Menus::StatusLine - defines the class TStatusLine

=cut

package TV::Menus::StatusLine;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TStatusLine
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::Menus::Const qw( cpStatusLine );
use TV::Drivers::Const qw( :evXXXX );
use TV::Drivers::Util qw( cstrlen );
use TV::Objects::DrawBuffer;
use TV::Views::Const qw(
  cmCommandSetChanged
  gfGrowLoY
  gfGrowHiX
  gfGrowHiY
  hcNoContext
  ofPreProcess
);
use TV::Views::Palette;
use TV::Views::View;
use TV::toolkit;

sub TStatusLine() { __PACKAGE__ }
sub name() { TStatusLine }

extends TView;

# declare attributes
slots items => ();
slots defs  => ();

# predeclare private methods
my (
  $drawSelect,
  $findItems,
  $itemMouseIsIn,
);

# declare local variables
my $hintSeparator;

sub BUILDARGS {    # \%args (%)
  my ( $class, %args ) = @_;
  assert ( $class and !ref $class );
  # 'required' arguments
  assert ( blessed $args{bounds} );
  assert ( exists $args{defs} );
  # 'isa' is undef or TStatusDef
  assert( !defined $args{defs} or blessed $args{defs} );
  return $class->SUPER::BUILDARGS( %args );
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( blessed $self );
  $self->{options}   |= ofPreProcess;
  $self->{eventMask} |= evBroadcast;
  $self->{growMode}   = gfGrowLoY | gfGrowHiX | gfGrowHiY;
  $self->$findItems();
  return;
} #/ sub new

sub from {    # $obj ($bounds, $aDefs|undef);
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 2 );
  return $class->new( bounds => $_[0], defs => $_[1] );
}

sub DEMOLISH {    # void ()
  my $self = shift;
  assert ( blessed $self );
  while ( $self->{defs} ) {
    my $T = $self->{defs};
    $self->{defs} = $self->{defs}{next};
    $self->disposeItems( $T->{items} );
    undef $T;
  }
  return;
}

sub disposeItems {    # void ($item)
  assert ( @_ == 2 );
  my $self = shift;
  assert ( blessed $self );
  alias: for my $item ( shift ) {
  while ( $item ) {
    alias: for my $T ( $item ) {
    $item = $item->next;
    undef $T;
    } #/ alias
  }
  return;
  } #/ alias
}

sub draw {    # void ()
  my $self = shift;
  assert ( blessed $self );
  $self->$drawSelect( undef );
  return;
}

my $palette;
sub getPalette {    # $palette ()
  my $self = shift;
  assert ( blessed $self );
  $palette ||= TPalette->new( cpStatusLine, length( cpStatusLine ) );
  return $palette;
}

sub handleEvent {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( blessed $self );
  assert ( blessed $event );
  $self->SUPER::handleEvent( $event );

  if ( $event->{what} == evMouseDown ) {
    my $T;
    do {
      my $mouse = $self->makeLocal( $event->{mouse}{where} );
      if ( $T != $self->$itemMouseIsIn( $mouse ) ) {
        $self->$drawSelect( $T = $self->$itemMouseIsIn( $mouse ) );
      }
    } while ( $self->mouseEvent( $event, evMouseMove ) );

    if ( $T && $self->commandEnabled( $T->{command} ) ) {
      $event->{what} = evCommand;
      $event->{message}{command} = $T->{command};
      $event->{message}{infoPtr} = undef;
      $self->putEvent( $event );
    }
    $self->clearEvent( $event );
    $self->drawView();
  } #/ if ( $event->{what} ==...)
  elsif ( $event->{what} == evKeyDown ) {
    my $T = $self->{items};
    while ( $T ) {
      if ( $event->{keyDown}{keyCode} == $T->{keyCode}
        && $self->commandEnabled( $T->{command} ) )
      {
        $event->{what} = evCommand;
        $event->{message}{command} = $T->{command};
        $event->{message}{infoPtr} = undef;
        return;
      }
      $T = $T->{next};
    } #/ while ( $T )
  } #/ elsif ( $event->{what} ==...)
  elsif ( $event->{what} == evBroadcast
    && $event->{message}{command} == cmCommandSetChanged
  ) {
    $self->drawView();
  }
  return;
} #/ sub handleEvent

sub hint {    # $str ($aHelpCtx)
  assert ( blessed shift );
  assert ( looks_like_number shift );
  return '';
}

sub update {    # void
  my $self = shift;
  assert ( blessed $self );
  my $p = $self->TopView();
  my $h = $p ? $p->getHelpCtx() : hcNoContext;
  if ( $self->{helpCtx} != $h ) {
    $self->{helpCtx} = $h;
    $self->$findItems();
    $self->drawView();
  }
  return;
} #/ sub update

$drawSelect = sub {    # void ($selected|undef)
  my ( $self, $selected ) = @_;
  my $b = TDrawBuffer->new();

  my $cNormal       = $self->getColor( 0x0301 );
  my $cSelect       = $self->getColor( 0x0604 );
  my $cNormDisabled = $self->getColor( 0x0202 );
  my $cSelDisabled  = $self->getColor( 0x0505 );
  $b->moveChar( 0, ' ', $cNormal, $self->{size}{x} );
  my $T = $self->{items};
  my $i = 0;

  while ( $T ) {
    if ( $T->{text} ) {
      my $l = cstrlen( $T->{text} );
      if ( $i + $l < $self->{size}{x} ) {
        no warnings 'uninitialized';
        my $color;
        if ( $self->commandEnabled( $T->{command} ) ) {
          $color = ( $T == $selected )
                 ? $cSelect 
                 : $cNormal;
        }
        else {
          $color = ( $T == $selected )
                 ? $cSelDisabled 
                 : $cNormDisabled;
        }
        $b->moveChar( $i, ' ', $color, 1 );
        $b->moveCStr( $i + 1, $T->{text}, $color );
        $b->moveChar( $i + $l + 1, ' ', $color, 1 );
      } #/ if ( $i + $l < $self->...)
      $i += $l + 2;
    } #/ if ( $T->{text} )
    $T = $T->{next};
  } #/ while ( $T )
  if ( $i < $self->{size}{x} - 2 ) {
    my $hintBuf = $self->hint( $self->{helpCtx} );
    if ( $hintBuf ne '' ) {
      $b->moveStr( $i, $hintSeparator, $cNormal );
      $i += 2;
      if ( length( $hintBuf ) + $i > $self->{size}{x} ) {
        $hintBuf = substr( $hintBuf, 0, $self->{size}{x} - $i );
      }
      $b->moveStr( $i, $hintBuf, $cNormal );
      $i += length( $hintBuf );
    }
  } #/ if ( $i < $self->{size...})
  $self->writeLine( 0, 0, $self->{size}{x}, 1, $b );
  return;
}; #/ sub drawSelect

$findItems = sub {    # void ()
  my $self = shift;
  my $p = $self->{defs};
  while ( $p 
    && ( $self->{helpCtx} < $p->{min} || $self->{helpCtx} > $p->{max} ) 
  ) {
    $p = $p->{next};
  }
  $self->{items} = $p ? $p->{items} : undef;
  return;
};

$itemMouseIsIn = sub {    # $statusItem|undef ($mouse)
  my ( $self, $mouse ) = @_;
  return undef
    if $mouse->{y} != 0;

  my $i = 0;
  my $T = $self->{items};

  while ( $T ) {
    if ( $T->{text} ) {
      my $k = $i + cstrlen( $T->{text} ) + 2;
      return $T 
        if $mouse->{x} >= $i && $mouse->{x} < $k;
      $i = $k;
    }
    $T = $T->{next};
  }
  return undef;
}; #/ sub itemMouseIsIn

1
