#!perl

use strict;
use warnings;

use Test::More qw( no_plan );

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Menus::Const';
  use_ok 'TV::Menus::Menu';
  use_ok 'TV::Menus::MenuItem';
  use_ok 'TV::Menus::SubMenu';
  use_ok 'TV::Menus::MenuView';
  use_ok 'TV::Menus::MenuBar';
  use_ok 'TV::Menus::StatusItem';
  use_ok 'TV::Menus::StatusDef';
}

isa_ok( TMenu->new(), TMenu );
isa_ok( TMenuItem->new( 'One', 1, 0x1234 ), TMenuItem );
isa_ok( TSubMenu->new( 'Two', 0x2345 ), TSubMenu );
isa_ok( TMenuView->new( bounds => TRect->new() ), TMenuView );
isa_ok( 
  TMenuBar->new( bounds => TRect->new(), menu => TMenu->new() ),
	TMenuBar 
);
isa_ok( TStatusItem->new( 'One', 0x1234, 1 ), TStatusItem );
isa_ok( TStatusDef->new( 1, 2 ), TStatusDef );
