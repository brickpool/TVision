#!perl

=pod

=head1 DESCRIPTION

These test cases cover the creation of the object, the setting and retrieving of
the fields as well as the behavior of the methods C<setBounds>, C<execute>, 
C<findItem>, C<getItemRect>, C<getHelpCtx>, C<getPalette>, C<handleEvent> and 
C<hotKey>. 

=cut

use strict;
use warnings;

use Test::More tests => 23;
use Test::Exception;

BEGIN {
  use_ok 'TV::Objects::Rect';
  require_ok 'TV::Drivers::Const';
  use_ok 'TV::Drivers::Event';
  use_ok 'TV::Views::Palette';
  use_ok 'TV::Menus::Menu';
  use_ok 'TV::Menus::MenuItem';
  use_ok 'TV::Menus::MenuView';
}

BEGIN {
  package MyMenuView;
  use TV::Drivers::Const qw( evKeyDown kbEsc );
  require TV::Menus::MenuView;
  use base 'TV::Menus::MenuView';
  sub getEvent {
    $_[1]->{what} = evKeyDown;
    $_[1]->{keyDown}{keyCode} = kbEsc;
  }
  $INC{"MyMenuView.pm"} = 1;
}

# Test object creation with menu and parent
my $menu = TMenu->new(
  TMenuItem->new( 'One', 1, 0x1234 ),
	TMenuItem->new( 'Two', 2, 0x5678 ) 
);
my $parent_menu = TMenuView->new(
  bounds => TRect->new(), menu => $menu, parentMenu => undef 
);
my $menu_view = MyMenuView->new(
  bounds => TRect->new(), menu => $menu, parentMenu => $parent_menu 
);
isa_ok( $menu_view, TMenuView, 'Object is of class TMenuView' );

# Test object creation without menu and parent
my $menu_view_no_menu = TMenuView->new( bounds => TRect->new() );
isa_ok( $menu_view_no_menu, TMenuView,
  'Object is of class TMenuView without menu and parent' );

# Test execute method
can_ok( $menu_view, 'execute' );
is( $menu_view->execute(), 0, 'execute returns correct value' );

# Test findItem method
can_ok( $menu_view, 'findItem' );
is( $menu_view->findItem( 'A' ), undef, 'findItem returns correct value' );

# Test getItemRect method
can_ok( $menu_view, 'getItemRect' );
is_deeply( $menu_view->getItemRect( TMenuItem->new( 'Three', 3, 0x9ABC ) ),
  TRect->new(), 'getItemRect returns correct value' );

# Test getHelpCtx method
can_ok( $menu_view, 'getHelpCtx' );
is( $menu_view->getHelpCtx(), 0, 'getHelpCtx returns correct value' );

# Test getPalette method
can_ok( $menu_view, 'getPalette' );
my $palette = $menu_view->getPalette();
isa_ok( $palette, TPalette, 'getPalette returns a TPalette object' );

# Test handleEvent method
can_ok( $menu_view, 'handleEvent' );
lives_ok { $menu_view->handleEvent( TEvent->new() ) }
  'handleEvent works correctly';

# Test hotKey method
can_ok( $menu_view, 'hotKey' );
is( $menu_view->hotKey( 0 ), undef, 'hotKey returns correct value' );

done_testing;
