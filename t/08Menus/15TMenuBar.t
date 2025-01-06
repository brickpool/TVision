#!perl

=pod

=head1 DESCRIPTION

These test cases check the creation of C<TMenuBar> objects, the C<draw> method 
and the C<getItemRect> method.

=cut

use strict;
use warnings;

use Test::More tests => 9;
use Test::Exception;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Menus::Menu';
  use_ok 'TV::Menus::SubMenu';
  use_ok 'TV::Menus::MenuItem';
  use_ok 'TV::Menus::MenuBar';
}

# Test case for the constructor
subtest 'constructor with menu' => sub {
  my $bounds   = new_TRect( 0, 0, 10, 10 );
  my $menu     = TMenu->new();
  my $menu_bar = new_TMenuBar( $bounds, $menu );
  isa_ok( $menu_bar, TMenuBar, 'TMenuBar object created' );
};

# Test case for the constructor with submenu
subtest 'constructor with submenu' => sub {
  my $bounds   = new_TRect( 0, 0, 10, 10 );
  my $submenu  = new_TSubMenu( "One", 1 );
  my $menu_bar = new_TMenuBar( $bounds, $submenu );
  isa_ok( $menu_bar, TMenuBar, 'TMenuBar object with submenu created' );
};

# Test draw method and constructor with hash
subtest 'draw method' => sub {
  my $bounds   = new_TRect( 0, 0, 10, 10 );
  my $menu     = TMenu->new();
  my $menu_bar = TMenuBar->new( bounds => $bounds, menu => $menu );
  can_ok( $menu_bar, 'draw' );
  lives_ok { $menu_bar->draw } 'draw works correctly';
};

# Test getItemRect method
subtest 'getItemRect method' => sub {
  my $bounds   = new_TRect( 0, 0, 10, 10 );
  my $item     = new_TMenuItem( "~T~wo", 2, 0x2345 );
  my $menu     = new_TMenu( $item );
  my $menu_bar = TMenuBar->new( bounds => $bounds, menu => $menu );
  can_ok( $menu_bar, 'getItemRect' );
  lives_ok { $menu_bar->getItemRect( $item ) } 'getItemRect works correctly';
};

done_testing;
