package TV::Menus::SubMenu;
# ABSTRACT: Class for a submenu off a menu bar or menu box 

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TSubMenu
  new_TSubMenu
);

use Carp ();
use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw( blessed );

use TV::Views::Const qw( hcNoContext );
use TV::Menus::Menu;
use TV::Menus::MenuItem;
use TV::toolkit;

sub TSubMenu() { __PACKAGE__ }
sub new_TSubMenu { __PACKAGE__->from(@_) }

extends TMenuItem;

sub from {    # $obj ($nm, $key, | $helpCtx)
  my $class = shift;
  assert( $class and !ref $class );
  assert ( @_ >= 2 && @_ <= 3 );
  SWITCH: for ( scalar @_ ) {
    $_ == 2 and return $class->new( name => $_[0], keyCode => $_[1], 
      helpCtx => hcNoContext );
    $_ == 3 and return $class->new( name => $_[0], keyCode => $_[1], 
      helpCtx => $_[2] );
  }
  return;
}

sub add_menu_item {    # $s ($s, $i)
  my ( $s, $i ) = @_;
  assert ( blessed $s );
  assert ( blessed $i and $i->isa( TMenuItem ) );
  my $sub = $s;
  while ( $sub->{next} ) {
    $sub = $sub->{next};
  }

  if ( !$sub->{subMenu} ) {
    $sub->{subMenu} = TMenu->new( items => $i );
  }
  else {
    my $cur = $sub->{subMenu}{items};
    while ( $cur->{next} ) {
      $cur = $cur->{next};
    }
    $cur->{next} = $i;
  }
  return $s;
} #/ sub add_menu_item

sub add_sub_menu {    # $s1 ($s1, $s2)
  my ( $s1, $s2 ) = @_;
  assert ( blessed $s1 );
  assert ( blessed $s2 and $s2->isa( TSubMenu ) );
  my $cur = $s1;
  while ( $cur->{next} ) {
    $cur = $cur->{next};
  }
  $cur->{next} = $s2;
  return $s1;
}

sub add {    # $s ($s, $s2|$i)
  assert ( blessed $_[0] );
  assert ( blessed $_[1] );
  assert ( not $_[2] );    # test if operands have been swapped
  blessed( $_[1] ) && $_[1]->isa( TSubMenu )
    ? goto &add_sub_menu
    : goto &add_menu_item
}

use overload
  '+' => \&add,
  fallback => 1;

1

__END__

=pod

=head1 NAME

TV::Menus::SubMenu - defines the class TSubMenu

=cut
