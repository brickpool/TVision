=pod

=head1 DESCRIPTION

These test cases verify the creation of I<TScroller> objects and ensure the 
correct behavior of its core methods. The tests cover the following 
functionality:

Object instantiation using I<new_TScroller> with required parameters. Retrieval 
of the palette via I<getPalette>. Bounds adjustment through I<changeBounds>. 
Scrolling operations using I<scrollTo> and limit configuration via I<setLimit>.
Event handling with I<handleEvent> for broadcast messages. State management 
through I<setState> and redraw checks using I<checkDraw>. Proper resource 
cleanup with I<shutDown>, ensuring scroll bars are cleared.

=back

=cut

use strict;
use warnings;

use Test::More tests => 17;
use Test::Exception;

BEGIN {
    use_ok 'TV::Objects::Rect';
    use_ok 'TV::Objects::Point';
    use_ok 'TV::Views::Palette';
    use_ok 'TV::Views::Scroller';
    use_ok 'TV::Views::ScrollBar';
    use_ok 'TV::Drivers::Const', qw( evBroadcast );
    use_ok 'TV::Views::Const', qw(
      cmScrollBarChanged 
      sfActive 
      sfDragging
    );
    use_ok 'TV::Drivers::Event';
}

# ScrollBars
my $hBar = TScrollBar->new(
  bounds => TRect->new( ax => 0, ay => 0, bx => 10, by => 1 ) );
my $vBar = TScrollBar->new(
  bounds => TRect->new( ax => 0, ay => 0, bx => 1, by => 10 ) );

# Test object creation
my $scroller;
subtest 'Object creation' => sub {
  my $bounds = TRect->new( ax => 0, ay => 0, bx => 20, by => 10 );
  lives_ok { $scroller = new_TScroller( $bounds, $hBar, $vBar ) }
    'TScroller object created';
  isa_ok( $scroller, TScroller );
}; #/ 'Object creation' => sub

# Test getPalette
subtest 'getPalette' => sub {
  can_ok( $scroller, 'getPalette' );
  my $palette;
  lives_ok { $palette = $scroller->getPalette() } 'getPalette executed';
  isa_ok( $palette, TPalette );
};

# Test changeBounds
subtest 'changeBounds' => sub {
  my $new_bounds = TRect->new( ax => 0, ay => 0, bx => 30, by => 15 );
  can_ok( $scroller, 'changeBounds' );
  lives_ok { $scroller->changeBounds( $new_bounds ) } 'changeBounds executed';
};

# Test scrollTo
subtest 'scrollTo' => sub {
  can_ok( $scroller, 'scrollTo' );
  lives_ok { $scroller->scrollTo( 5, 5 ) } 'scrollTo executed';
};

# Test setLimit
subtest 'setLimit' => sub {
  can_ok( $scroller, 'setLimit' );
  lives_ok { $scroller->setLimit( 100, 50 ) } 'setLimit executed';
};

# Test handleEvent
subtest 'handleEvent' => sub {
  my $event = TEvent->new( what => evBroadcast,
    message => { command => cmScrollBarChanged, infoPtr => $hBar } );
  can_ok( $scroller, 'handleEvent' );
  lives_ok { $scroller->handleEvent( $event ) } 'handleEvent executed';
};

# Test setState
subtest 'setState' => sub {
  can_ok( $scroller, 'setState' );
  lives_ok { $scroller->setState( sfActive | sfDragging, 1 ) }
  'setState executed';
};

# Test checkDraw
subtest 'checkDraw' => sub {
  can_ok( $scroller, 'checkDraw' );
  lives_ok { $scroller->checkDraw() } 'checkDraw executed';
};

# Test shutDown
subtest 'shutDown' => sub {
  can_ok( $scroller, 'shutDown' );
  lives_ok { $scroller->shutDown() } 'shutDown executed';
  ok( !defined $scroller->{hScrollBar}, 'hScrollBar cleared' );
  ok( !defined $scroller->{vScrollBar}, 'vScrollBar cleared' );
};

done_testing();
