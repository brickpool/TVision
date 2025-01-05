=pod

=head1 DESCRIPTION

These test cases check the creation of I<TFrame> objects, as well as the 
I<draw>, I<getPalette>, I<handleEvent>, and I<setState> methods. 

=cut

use strict;
use warnings;

use Test::More tests => 13;
use Test::Exception;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Drivers::Const', qw( evMouseDown );
  use_ok 'TV::Drivers::Event';
  use_ok 'TV::Views::Const', qw( sfActive );
  use_ok 'TV::Views::Palette';
  use_ok 'TV::Views::Group';
  use_ok 'TV::Views::Frame';
}

# Mocking TWindow for testing purposes
BEGIN {
  package MyWindow;
  use TV::toolkit;
  extends 'TV::Views::Group';
  slots flags  => ( default => sub { 0 } );
  slots number => ( default => sub { 0 } );
  sub getTitle { 'title' }
  $INC{"MyWindow.pm"} = 1;
}

use_ok 'MyWindow';

my (
  $bounds,
  $frame,
  $owner,
);

# Test case for the constructor
subtest 'Test object creations' => sub {
  $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 10 );
  isa_ok( $bounds, TRect, 'Object is of class TRect' );
  $frame = TFrame->new( bounds => $bounds );
  isa_ok( $frame, TFrame, 'TFrame object created' );
};

# Test case for the draw method
subtest 'draw' => sub {
  my $r  = TRect->new( ax => 0, ay => 0, bx => 20, by => 20 );
  $owner = MyWindow->new( bounds => $r );
  $owner->insertView( $frame, undef );
  $frame->{state} = 0;
  can_ok( $frame, 'draw' );
  lives_ok { $frame->draw() } 'TFrame draw method executed';
};

# Test case for the getPalette method
subtest 'getPalette' => sub {
  can_ok( $frame, 'getPalette' );
  my $palette = $frame->getPalette();
  isa_ok( $palette, TPalette, 'Palette object returned' );
};

# Test case for the handleEvent method
subtest 'handleEvent' => sub {
  my $event = TEvent->new( what => evMouseDown,
    mouse => { where => { x => 3, y => 0 }, eventFlags => 0 } 
  );
  can_ok( $frame, 'handleEvent' );
  lives_ok { $frame->handleEvent( $event ) } 
    'TFrame handleEvent method executed';
};

# Test case for the setState method
subtest 'setState' => sub {
  can_ok( $frame, 'setState' );
  lives_ok { $frame->setState( sfActive, 1 ) } 
    'TFrame setState method executed';
};

done_testing;
