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
  use_ok 'TV::Menus::StatusLine';
}

isa_ok( TMenu->new(), TMenu );
isa_ok( TMenuItem->init( 'One', 1, 0x1234 ), TMenuItem );
isa_ok( TSubMenu->init( 'Two', 0x2345 ), TSubMenu );
isa_ok( TMenuView->init( TRect->new() ), TMenuView );
isa_ok( TMenuBar->init( TRect->new(), TMenu->new() ), TMenuBar );
isa_ok( TStatusItem->init( 'One', 0x1234, 1 ), TStatusItem );
isa_ok( TStatusDef->init( 1, 2 ), TStatusDef );
isa_ok( TStatusLine->init( TRect->new(), undef ), TStatusLine );
