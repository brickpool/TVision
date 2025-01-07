package TV::Menus;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TV::Menus::Const;
use TV::Menus::Menu;
use TV::Menus::MenuItem;
use TV::Menus::SubMenu;
use TV::Menus::MenuView;
use TV::Menus::MenuBar;
use TV::Menus::StatusItem;
use TV::Menus::StatusDef;
use TV::Menus::StatusLine;

sub import {
  my $target = caller;
  TV::Menus::Const->import::into( $target, qw( :all ) );
  TV::Menus::Menu->import::into( $target );
  TV::Menus::MenuItem->import::into( $target );
  TV::Menus::SubMenu->import::into( $target );
  TV::Menus::MenuView->import::into( $target );
  TV::Menus::MenuBar->import::into( $target );
  TV::Menus::StatusItem->import::into( $target );
  TV::Menus::StatusDef->import::into( $target );
  TV::Menus::StatusLine->import::into( $target );
}

sub unimport {
  my $caller = caller;
  TV::Menus::Const->unimport::out_of( $caller );
  TV::Menus::Menu->unimport::out_of( $caller );
  TV::Menus::MenuItem->unimport::out_of( $caller );
  TV::Menus::SubMenu->unimport::out_of( $caller );
  TV::Menus::MenuView->unimport::out_of( $caller );
  TV::Menus::MenuBar->unimport::out_of( $caller );
  TV::Menus::StatusItem->unimport::out_of( $caller );
  TV::Menus::StatusDef->unimport::out_of( $caller );
  TV::Menus::StatusLine->unimport::out_of( $caller );
}

1;
