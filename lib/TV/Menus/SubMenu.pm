=pod

=head1 NAME

TV::Menus::SubMenu - defines the class TSubMenu

=cut

package TV::Menus::SubMenu;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TSubMenu
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::Views::Const qw( hcNoContext );
use TV::Menus::Menu;
use TV::Menus::MenuItem;

sub TSubMenu() { __PACKAGE__ }

use base TMenuItem;

sub BUILDARGS {    # \%args (@|%)
  my ( $class, @args ) = @_;
  assert( $class and !ref $class );
  splice( @args, 2, 0, 0 ) if @_ <= 4;
  return $class->SUPER::BUILDARGS( @args );
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
    $sub->{subMenu} = TMenu->new( $i );
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
