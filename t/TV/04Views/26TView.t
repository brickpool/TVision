=pod

=head1 DECRIPTION

The following test cases of class I<TView> cover the methods I<getColor>, 
I<getPalette>, I<mapColor>, I<getState>, I<select>, I<setState>, I<keyEvent>, 
I<mouseEvent>, I<makeGlobal> and I<makeLocal>.

=cut

use strict;
use warnings;

use Test::More tests => 20;
use Test::Exception;

BEGIN {
  use_ok 'TV::Objects::Point';
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Drivers::Const', qw( EV_MOUSE_DOWN );
  use_ok 'TV::Drivers::Event';
  use_ok 'TV::Views::Const', qw( SF_VISIBLE );
  use_ok 'TV::Views::Palette';
  use_ok 'TV::Views::View';
}

BEGIN {
  package MyOwner;
  use TV::Views::View;
  use parent TView;
  my $toggle = 1;
  sub getEvent { 
    $toggle = 1 - $toggle; 
    $_[1]->{what} = 1 << 4 * $toggle; # $toogle ? EV_MOUSE_DOWN : EV_KEY_DOWN
  }
  $INC{"MyOwner.pm"} = 1;
}

use_ok 'MyOwner';

my $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 10 );
isa_ok( $bounds, TRect );

my $owner = MyOwner->new( bounds => $bounds );
isa_ok( $owner, 'MyOwner' );

# Test the getPalette method
subtest 'getPalette method' => sub {
  my $view    = TView->new( bounds => $bounds );
  my $palette = $view->getPalette();
  isa_ok( $palette, TPalette, 'getPalette method returns a TPalette object' );
};

# Test the mapColor method
subtest 'mapColor method' => sub {
  my $view = TView->new( bounds => $bounds );
  is( $view->mapColor( 2 ), 2, 'mapColor method returns correct color' );
};

# Test the getColor method
subtest 'getColor method' => sub {
  my $view = TView->new( bounds => $bounds );
  is( 
    $view->getColor( 0x100 ), 
    ( 0x100 | TView->{errorAttr} ),
    'getColor method returns correct color'
  );
};

# Test the getState method
subtest 'getState method' => sub {
  my $view = TView->new( bounds => $bounds );
  ok( $view->getState( SF_VISIBLE ), 'getState method returns true' );
};

# Test the select method
subtest 'select method' => sub {
  my $view = TView->new( bounds => $bounds );
  lives_ok { $view->select() }
    'select method executed without errors';
};

# Test the setState method
subtest 'setState method' => sub {
  my $view = TView->new( bounds => $bounds );
  $view->setState( SF_VISIBLE, 1 );
  ok( $view->{state} & SF_VISIBLE, 'state is set correctly after setState' );
};

# Test the keyEvent method
subtest 'keyEvent method' => sub {
  my $view  = TView->new( bounds => $bounds );
  my $event = TEvent->new();
  $view->owner( $owner );
  lives_ok { $view->keyEvent( $event ) }
    'keyEvent method executed without errors';
};

# Test the mouseEvent method
subtest 'mouseEvent method' => sub {
  my $view  = TView->new( bounds => $bounds );
  my $event = TEvent->new();
  $view->owner( $owner );
  ok( $view->mouseEvent( $event, EV_MOUSE_DOWN ),
    'mouseEvent method returns true' );
};

# Test the makeGlobal method
subtest 'makeGlobal method' => sub {
  my $view   = TView->new( bounds => $bounds );
  my $point  = TPoint->new( x => 5, y => 10 );
  my $global = $view->makeGlobal( $point );
  isa_ok( $global, TPoint, 'makeGlobal method returns a TPoint object' );
  is( $global->{x}, 5,  'global.x is set correctly' );
  is( $global->{y}, 10, 'global.y is set correctly' );
};

# Test the makeLocal method
subtest 'makeLocal method' => sub {
  my $view  = TView->new( bounds => $bounds );
  my $point = TPoint->new( x => 5, y => 10 );
  my $local = $view->makeLocal( $point );
  isa_ok( $local, TPoint, 'makeLocal method returns a TPoint object' );
  is( $local->{x}, 5,  'local.x is set correctly' );
  is( $local->{y}, 10, 'local.y is set correctly' );
};

done_testing;
