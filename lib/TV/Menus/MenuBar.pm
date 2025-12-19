package TV::Menus::MenuBar;
# ABSTRACT: TMenuBar object manages the menu bar across the top of the app.

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
);

use TV::Drivers::Util qw( cstrlen );
use TV::Menus::Menu;
use TV::Menus::MenuView;
use TV::Menus::SubMenu;
use TV::Views::DrawBuffer;
use TV::Objects::Rect;
use TV::Views::Const qw(
  gfGrowHiX
  ofPreProcess
);
use TV::toolkit;

sub TMenuBar() { __PACKAGE__ }
sub name() { 'TMenuBar' }
sub new_TMenuBar { __PACKAGE__->from(@_) }

extends TMenuView;

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  local $Params::Check::PRESERVE_CASE = 1;
  return STRICT ? check( {
    # 'required' arguments (note: 'menu' can be undefined )
    bounds => {
      required => 1,
      defined  => 1,
      allow    => sub { blessed shift }
    },
    menu => {
      required => 1,
      allow    => sub { !defined $_[0] or blessed $_[0] }
    },
  } => { @_ } ) || Carp::confess( last_error ) : { @_ };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( blessed $self );
  $self->{menu} = TMenu->new( items => $self->{menu} )
    if $self->{menu} 
    && $self->{menu}->isa(TSubMenu);
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

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  undef $self->{menu};
  return;
}

sub draw {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
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

sub getItemRect {    # $rect ($item|undef)
  my ( $self, $item ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( !defined $item or blessed $item );
  my $r = TRect->new( ax => 1, ay => 0, bx => 1, by => 1 );
  my $p = $self->{menu}{items};
  while ( 1 ) {
    $r->{a}{x} = $r->{b}{x};
    if ( $p->{name} ) {
      $r->{b}{x} += cstrlen( $p->{name} ) + 2;
    }
    {
      no warnings 'uninitialized';
      return $r
        if $p == $item;
    }
    $p = $p->{next};
  }
} #/ sub getItemRect

1

__END__

=pod

=head1 NAME

TV::Menus::MenuBar - manages the menu bar at the top of the app.

=head1 DESCRIPTION

The TMenuBar object manages the menu bar across the top of the application
screen.

=head1 METHODS

=head2 new

  my $menuBar = TMenuBar->new(bounds => $bounds, menu => $aMenu | undef);

=head2 DESTROY

  $self->DESTROY();

=head2 draw

  $self->draw();

=head2 from

  my $menuBar = TMenuBar->from($bounds, $aMenu | undef);

=head2 getItemRect

  my $rect = $self->getItemRect($item | undef);

=cut
