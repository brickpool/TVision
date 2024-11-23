use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TV::Drivers::Event';
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::App::Background';
  use_ok 'TV::App::DeskTop';
}

# Test object creation
my $desktop = TDeskTop->new( bounds => TRect->new() );
isa_ok( $desktop, TDeskTop, 'Object is of class TDeskTop' );

# Test shutDown method
can_ok( $desktop, 'shutDown' );
lives_ok { $desktop->shutDown() }
  'shutDown works correctly';

# Test cascade method
can_ok( $desktop, 'cascade' );
lives_ok { $desktop->cascade( TRect->new() ) }
  'cascade works correctly';

# Test handleEvent method
can_ok( $desktop, 'handleEvent' );
my $event = TEvent->new();
lives_ok { $desktop->handleEvent( $event ) }
  'handleEvent works correctly';

# Test initBackground method
can_ok( $desktop, 'initBackground' );
my $background = $desktop->initBackground( TRect->new() );
isa_ok( $background, TBackground,
	'initBackground returns a TBackground object' );

# Test tile method
can_ok( $desktop, 'tile' );
lives_ok { $desktop->tile( TRect->new() ) }
  'tile works correctly';

# Test tileError method
can_ok( $desktop, 'tileError' );
lives_ok { $desktop->tileError() }
   'tileError works correctly';

done_testing;
