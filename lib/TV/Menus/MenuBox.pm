package TV::Menus::MenuBox;

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

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use List::Util qw( max );
use Params::Check qw(
  check
  last_error
);
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::Menus::MenuView;
use TV::Objects::DrawBuffer;
use TV::Objects::Rect;
use TV::Views::Const qw(
  sfShadow
  ofPreProcess
);
use TV::toolkit;

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
  $frameLine,
  $drawLine,
);

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  local $Params::Check::PRESERVE_CASE = 1;
  my $args = STRICT ? check( {
    # 'required' arguments (note: 'menu' and 'parentMenu' can be undefined)
    bounds => {
      required => 1, 
      defined  => 1, 
      allow => sub { blessed shift },
    },
    menu => {
      required => 1, 
      allow    => sub { !defined $_[0] or blessed $_[0] },
    },
    parentMenu => {
      required => 1, 
      allow    => sub { !defined $_[0] or blessed $_[0] },
    },
  } => { @_ } ) || Carp::confess( last_error ) : { @_ };
  $args->{bounds} = $class->getRect( $args->{bounds}, $args->{menu} );
  return $args;
}

sub BUILD {    # void (| \%args)
  my $self = shift;
  assert( blessed $self );
  $self->{state} |= sfShadow;
  $self->{options} |= ofPreProcess;
  return;
}

sub from {    # $obj ($bounds, $aMenu|undef, $aParent|undef);
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 3 );
  return $class->SUPER::from( @_ );
}

my ( $cNormal, $color );

sub draw {    # void ()
  my $self = shift;
  assert ( blessed $self );
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
  my ( $self, $item ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( !defined $item or blessed $item );
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

sub getRect {    # $rect ($bounds, $aMenu|undef)
  my ( $class, $bounds, $aMenu ) = @_;
  assert ( @_ == 3 );
  assert ( $class and !ref $class );
  assert ( ref $bounds );
  assert ( !defined $aMenu or blessed $aMenu );
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
} #/ sub getRect

$frameLine = sub {    # void ($b, $n)
  my ( $self, $b, $n ) = @_;
  $b->moveBuf(
    0, [ unpack 'C*' => substr( $frameChars, $n, 2 ) ], $cNormal, 2 );
  $b->moveChar(
    2, substr( $frameChars, $n + 2, 1 ), $color, $self->{size}{x} - 4 );
  $b->moveBuf( $self->{size}{x} - 2,
    [ unpack 'C*' => substr( $frameChars, $n + 3, 2 ) ], $cNormal, 2 );
  return;
};

$drawLine = sub {    # void ($b)
  ...
};

1
