use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Menus::Menu';
  use_ok 'TV::Menus::MenuItem';
  use_ok 'TV::Menus::MenuBox';
}

BEGIN {
  package MyMenuView;
  use TV::Drivers::Const qw( evKeyDown kbEsc );
  use TV::toolkit;
  extends 'TV::Menus::MenuView';
  sub getEvent {
    $_[1]->{what} = evKeyDown;
    $_[1]->{keyDown}{keyCode} = kbEsc;
  }
  $INC{"MyMenuView.pm"} = 1;
}

my ( $bounds, $item1, $item2, $menu, $menuBox );

# Test case for the constructor
subtest 'constructor' => sub {
  $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 10 );
  $item1 = new_TMenuItem( 'One', 1, 0x1234 );
  $item2 = new_TMenuItem( 'Two', 2, 0x5678 );
  $menu = new_TMenu( $item1, $item2 );
  $menuBox = TMenuBox->new(
    bounds => $bounds, menu => $menu, parentMenu => undef
  );
  isa_ok( $menuBox, TMenuBox, 'Object is of class TMenuBox' );
};

# Test case for the draw method
subtest 'draw' => sub {
  can_ok( $menuBox, 'draw' );
  lives_ok { $menuBox->draw() }
    'TMenuBox draw method executed';
};

# Test case for the getItemRect method
subtest 'getItemRect' => sub {
  can_ok( $menuBox, 'getItemRect' );
  my $rect = $menuBox->getItemRect( $item1 );
  isa_ok( $rect, TRect, 'Item rect returned' );
};

# Test case for the getRect class method
subtest 'getItemRect' => sub {
  can_ok( TMenuBox, 'getRect' );
  my $rect = TMenuBox->getRect( $bounds, $menu );
  isa_ok( $rect, TRect, 'TRect returned' );
};

done_testing();
