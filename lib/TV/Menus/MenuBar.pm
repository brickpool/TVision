=pod

=head1 NAME

TV::Menus::MenuBar - defines the class TMenuBar

=cut

package TV::Menus::MenuBar;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TMenuBar
  new_TMenuBar
);

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

use TV::Drivers::Util qw( cstrlen );
use TV::Menus::Menu;
use TV::Menus::MenuView;
use TV::Menus::SubMenu;
use TV::Objects::DrawBuffer;
use TV::Objects::Rect;
use TV::Views::Const qw(
  gfGrowHiX
  ofPreProcess
);
use TV::toolkit;

sub TMenuBar() { __PACKAGE__ }
sub name() { TMenuView }
sub new_TMenuBar { __PACKAGE__->from(@_) }

extends TMenuView;

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  return STRICT ? check( {
    # 'required' arguments (note: 'menu' can be undefined )
    bounds => { required => 1, defined => 1, allow => sub { blessed shift } },
    menu => { required => 1, allow => sub { !defined $_[0] or blessed $_[0] } },
  } => { @_ } ) || Carp::confess( last_error ) : { @_ };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( blessed $self );
  $self->{menu} = TMenu->new( items => $self->{menu} )
    if $self->{menu} && $self->{menu}->isa(TSubMenu);
  $self->{growMode} = gfGrowHiX;
  $self->{options} |= ofPreProcess;
  return;
}

sub from {    # $obj ($bounds, $aMenu|undef)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 2 );
  return $class->new( bounds => $_[0], menu => $_[1] );
}

sub DEMOLISH {    # void ()
  my $self = shift;
  assert ( blessed $self );
  undef $self->{menu};
  return;
}

sub draw {    # void ()
  my $self = shift;
  assert ( blessed $self );
  my $color;
  my ( $x, $l );
  my $p;
  my $b = TDrawBuffer->new();

  my $cNormal       = $self->getColor( 0x0301 );
  my $cSelect       = $self->getColor( 0x0604 );
  my $cNormDisabled = $self->getColor( 0x0202 );
  my $cSelDisabled  = $self->getColor( 0x0505 );
  $b->moveChar( 0, ' ', $cNormal, $self->{size}{x} );
  if ( $self->{menu} ) {
    $x = 1;
    $p = $self->{menu}{items};
    while ( $p ) {
      if ( $p->{name} ) {
        $l = cstrlen( $p->{name} );
        if ( $x + $l < $self->{size}{x} ) {
          no warnings 'uninitialized';
          if ( $p->{disabled} ) {
            $color = ( $p == $self->{current} ) 
              ? $cSelDisabled 
              : $cNormDisabled;
          }
          else {
            $color = ( $p == $self->{current} ) 
              ? $cSelect 
              : $cNormal;
          }
          $b->moveChar( $x, ' ', $color, 1 );
          $b->moveCStr( $x + 1, $p->{name}, $color );
          $b->moveChar( $x + $l + 1, ' ', $color, 1 );
        } #/ if ( $x + $l < $self->...)
        $x += $l + 2;
      } #/ if ( $p->{name} )
      $p = $p->{next};
    } #/ while ( $p )
  } #/ if ( $self->{menu} )
  $self->writeBuf( 0, 0, $self->{size}{x}, 1, $b );
} #/ sub draw

sub getItemRect {    # $rect ($item)
  no warnings 'uninitialized';
  my ( $self, $item ) = @_;
  assert ( blessed $self );
  assert ( blessed $item );
  my $r = TRect->new( ax => 1, ay => 0, bx => 1, by => 1 );
  my $p = $self->{menu}{items};
  while ( 1 ) {
    $r->{a}{x} = $r->{b}{x};
    if ( $p->{name} ) {
      $r->{b}{x} += cstrlen( $p->{name} ) + 2;
    }
    return $r 
      if $p == $item;
    $p = $p->{next};
  }
} #/ sub getItemRect

1
