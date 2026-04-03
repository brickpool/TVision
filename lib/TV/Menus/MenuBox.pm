package TV::Menus::MenuBox;
# ABSTRACT: Pull-down or pop-up menu box

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TMenuBox
  new_TMenuBox
);

use PerlX::Assert::PP;
use List::Util qw( max );
use TV::toolkit;
use TV::toolkit::Params qw( signature );
use TV::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TV::Menus::MenuView;
use TV::Objects::Rect;
use TV::Views::Const qw(
  sfShadow
  ofPreProcess
);
use TV::Views::DrawBuffer;

sub TMenuBox() { __PACKAGE__ }
sub name { 'TMenuBox' }
sub new_TMenuBox { __PACKAGE__->from(@_) }

extends TMenuView;

# declare global variables
our $frameChars =
  # for UnitedStates code page
  " \332\304\277  \300\304\331  \263 \263  \303\304\264 ";

# predeclare private methods
my (
  $getRect,
  $frameLine,
  $drawLine,
);

sub _getRect { goto &$getRect }
$getRect = sub {    # $rect ($bounds, $aMenu|undef)
  my ( $class, $bounds, $aMenu ) = @_;
  assert ( @_ == 3 );
  assert ( is_Str $class );
  assert ( is_Object $bounds );
  assert ( !defined $aMenu or is_Object $aMenu );
  my $w = 10;
  my $h = 2;
  if ( $aMenu ) {
    for ( my $p = $aMenu->{items} ; $p ; $p = $p->{next} ) {
      if ( $p->{name} ) {
        my $l = length( $p->{name} ) + 6;
        if ( !$p->{command} ) {
          $l += 3
        }
        elsif ( $p->{param} ) {
          $l += length( $p->{param} ) + 2
        }
        $w = max( $l, $w );
      }
      $h++;
    }
  } #/ if ( $aMenu )

  my $r = $bounds->clone();

  if ( $r->{a}{x} + $w < $r->{b}{x} ) {
    $r->{b}{x} = $r->{a}{x} + $w;
  }
  else {
    $r->{a}{x} = $r->{b}{x} - $w;
  }

  if ( $r->{a}{y} + $h < $r->{b}{y} ) {
    $r->{b}{y} = $r->{a}{y} + $h;
  }
  else {
    $r->{a}{y} = $r->{b}{y} - $h;
  }

  return $r;
}; #/ sub $getRect

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      bounds     => Object,
      menu       => Maybe[Object], { alias => 'aMenu' },
      parentMenu => Maybe[Object], { alias => 'aParentMenu' },
    ],
    caller_level => +1,
  );
  my ( $class, $args1 ) = $sig->( @_ );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  my $args2 = $class->SUPER::BUILDARGS(
    bounds => $class->$getRect( $args1->{bounds}, $args1->{menu} ),
  );
  return { %$args1, %$args2 };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{state} |= sfShadow;
  $self->{options} |= ofPreProcess;
  return;
}

sub from {    # $obj ($bounds, $aMenu|undef, $aParent|undef);
  state $sig = signature(
    method => 1,
    pos => [Object, Maybe[Object], Maybe[Object]],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], menu => $args[1], 
    parentMenu => $args[2]);
}

my ( $cNormal, $color );

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $b = TDrawBuffer->new();

  $cNormal = $self->getColor( 0x0301 );
  my $cSelect       = $self->getColor( 0x0604 );
  my $cNormDisabled = $self->getColor( 0x0202 );
  my $cSelDisabled  = $self->getColor( 0x0505 );
  my $y             = 0;
  $color = $cNormal;
  $self->$frameLine( $b, 0 );
  $self->writeBuf( 0, $y++, $self->{size}{x}, 1, $b );

  if ( $self->{menu} ) {
    for ( my $p = $self->{menu}{items} ; $p ; $p = $p->{next} ) {
      $color = $cNormal;
      if ( !$p->{name} ) {
        $self->$frameLine( $b, 15 );
      }
      else {
        {
          no warnings 'uninitialized';
          if ( $p->{disabled} ) {
            $color = ( $p == $self->{current} ) 
              ? $cSelDisabled 
              : $cNormDisabled;
          }
          elsif ( $p == $self->{current} ) {
            $color = $cSelect;
          }
        }
        $self->$frameLine( $b, 10 );
        $b->moveCStr( 3, $p->{name}, $color );
        if ( !$p->{command} ) {
          $b->putChar( $self->{size}{x} - 4, 16 );
        }
        elsif ( $p->{param} ) {
          $b->moveStr( $self->{size}{x} - 3 - length( $p->{param} ), 
            $p->{param}, $color );
        }
      } #/ else [ if ( !$p->{name} ) ]
      $self->writeBuf( 0, $y++, $self->{size}{x}, 1, $b );
    } #/ for ( my $p = $self->{menu...})
  } #/ if ( $self->{menu} )
  $color = $cNormal;
  $self->$frameLine( $b, 5 );
  $self->writeBuf( 0, $y, $self->{size}{x}, 1, $b );
  return;
} #/ sub draw

sub getItemRect {    # $rect ($item|undef)
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Object]],
  );
  my ( $self, $item ) = $sig->( @_ );
  my $y = 1;
  my $p = $self->{menu}{items};

  {
    no warnings 'uninitialized';
    while ( $p != $item ) {
      $y++;
      $p = $p->{next};
    }
  }
  return TRect->new(
    ax => 2,
    ay => $y,
    bx => $self->{size}{x} - 2,
    by => $y + 1,
  );
} #/ sub getItemRect

$frameLine = sub {    # void ($b, $n)
  my ( $self, $b, $n ) = @_;
  assert ( @_ == 3 );
  assert ( is_Object $self );
  assert ( is_ArrayLike $b );
  assert ( is_Int $n );
  $b->moveBuf(
    0, [ unpack 'W*' => substr( $frameChars, $n, 2 ) ], $cNormal, 2 );
  $b->moveChar(
    2, substr( $frameChars, $n + 2, 1 ), $color, $self->{size}{x} - 4 );
  $b->moveBuf( $self->{size}{x} - 2,
    [ unpack 'W*' => substr( $frameChars, $n + 3, 2 ) ], $cNormal, 2 );
  return;
};

$drawLine = sub {    # void ($b)
  my ( $self, $b ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_HashLike $b );
  ...
};

1
