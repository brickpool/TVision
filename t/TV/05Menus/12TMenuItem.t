#!perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;

BEGIN {
  use_ok 'TV::Views::View';
  use_ok 'TV::Menus::MenuItem';
}

# Test object creation with command
my $menu_item = TMenuItem->new( 'File', 1, 0x1234, 0, 'param' );
isa_ok( $menu_item, TMenuItem, 'Object is of class TMenuItem' );

# Test object creation with submenu
my $submenu = TMenuItem->new( 'Edit', 0x5678, undef );
isa_ok( $submenu, TMenuItem, 'Object is of class TMenuItem' );

# Test append method
can_ok( $menu_item, 'append' );
$menu_item->append( $submenu );
is( $menu_item->{next}, $submenu, 'append sets next correctly' );

# Test newLine method
can_ok( TMenuItem, 'newLine' );
my $newline = newLine();
isa_ok( $newline, TMenuItem, 'newLine returns a TMenuItem object' );

# Test DESTROY method
can_ok( $menu_item, 'DESTROY' );
lives_ok { $menu_item->DESTROY() }
  'DESTROY works correctly';

done_testing;
