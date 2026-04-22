package TV::Menus::StatusLine;
# ABSTRACT: Message line for the bottom of the application screen

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TStatusLine
  new_TStatusLine
);

use TV::toolkit;
use TV::toolkit::Types qw(
  Maybe
  is_Object
  :types
);

use TV::Menus::Const qw( cpStatusLine );
use TV::Drivers::Const qw( :evXXXX );
use TV::Drivers::Util qw( cstrlen );
use TV::Views::DrawBuffer;
use TV::Views::Const qw(
  cmCommandSetChanged
  :gfXXXX
  hcNoContext
  ofPreProcess
);
use TV::Views::Palette;
use TV::Views::View;

sub TStatusLine() { __PACKAGE__ }
sub name() { 'TStatusLine' }
sub new_TStatusLine { __PACKAGE__->from(@_) }

extends TView;

# declare global variables
our $hintSeparator = "\xB3 ";

# protected attributes
has items => ( is => 'ro' );
has defs  => ( is => 'ro', default => sub { die 'required' } );

# predeclare private methods
my (
  $drawSelect,
  $findItems,
  $itemMouseIsIn,
);

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      bounds => Object,
      defs   => Maybe[Object], { alias => 'aDefs' },
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
  $self->{options}   |= ofPreProcess;
  $self->{eventMask} |= evBroadcast;
  $self->{growMode}   = gfGrowLoY | gfGrowHiX | gfGrowHiY;
  $self->$findItems();
  return;
} #/ sub new

sub from {    # $obj ($bounds, $aDefs|undef);
  state $sig = signature(
    method => 1,
    pos    => [ Object, Maybe[Object] ],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], defs => $args[1] );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  while ( $self->{defs} ) {
    my $T = $self->{defs};
    $self->{defs} = $self->{defs}{next};
    $self->disposeItems( $T->{items} );
    undef $T;
  }
  return;
}

sub disposeItems {    # void ($item|undef)
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Object]],
  );
  my ( $self, $item ) = $sig->( @_ );
  while ( $item ) {
    alias: for my $T ( $item ) {
    $item = $item->next;
    undef $T;
    } #/ alias
  }
  return;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->$drawSelect( undef );
  return;
}

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cpStatusLine, 
    size => length( cpStatusLine ),
  );
  return $palette->clone();
}

sub handleEvent {    # void ($event)
  no warnings 'uninitialized';
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  $self->SUPER::handleEvent( $event );

  SWITCH: for ( $event->{what} ) {
    $_ == evMouseDown and do {
      my $T;
      do {
        my $mouse = $self->makeLocal( $event->{mouse}{where} );
        if ( $T != $self->$itemMouseIsIn( $mouse ) ) {
          $self->$drawSelect( $T = $self->$itemMouseIsIn( $mouse ) );
        }
      } while ( $self->mouseEvent( $event, evMouseMove ) );

      if ( $T && TView->commandEnabled( $T->{command} ) ) {
        $event->{what} = evCommand;
        $event->{message}{command} = $T->{command};
        $event->{message}{infoPtr} = undef;
        $self->putEvent( $event );
      }
      $self->clearEvent( $event );
      $self->drawView();
      last;
    };
    $_ == evKeyDown and do {
      my $T = $self->{items};
      while ( $T ) {
        if ( $event->{keyDown}{keyCode} == $T->{keyCode}
          && TView->commandEnabled( $T->{command} ) )
        {
          $event->{what} = evCommand;
          $event->{message}{command} = $T->{command};
          $event->{message}{infoPtr} = undef;
          return;
        }
        $T = $T->{next};
      } #/ while ( $T )
      last;
    };
    $_ == evBroadcast and do {
      if ( $event->{message}{command} == cmCommandSetChanged
      ) {
        $self->drawView();
      }
      last;
    };
  }
  return;
} #/ sub handleEvent

sub hint {    # $str ($aHelpCtx)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $aHelpCtx ) = $sig->( @_ );
  return '';
}

sub update {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
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
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( !defined $selected or is_Object $selected );
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
        if ( TView->commandEnabled( $T->{command} ) ) {
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
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
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
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_HashLike $mouse );
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

__END__

=pod

=head1 NAME

TV::Menus::StatusLine - defines the class TStatusLine

=cut
