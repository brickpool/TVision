#!perl

use strict;
use warnings;

use Test::More qw( no_plan );

BEGIN {
  use_ok 'TV::Menus::Const';
  use_ok 'TV::Menus::Menu';
  use_ok 'TV::Menus::MenuItem';
  use_ok 'TV::Menus::SubMenu';
  use_ok 'TV::Menus::MenuView';
}

isa_ok( TMenu->new(), TMenu );
isa_ok( TMenuItem->new( 'One', 1, 0x1234 ), TMenuItem );
isa_ok( TSubMenu->new( 'Two', 0x2345 ), TSubMenu );
