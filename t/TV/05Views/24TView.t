=pod

=head1 DESCRIPTION

The following test cases of class I<TView> cover the methods I<clearEvent>, 
I<eventAvail>, I<getEvent>, I<handleEvent> and I<putEvent>.

=cut

use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Drivers::Const', qw( :evXXXX );
  use_ok 'TV::Drivers::Event';
  use_ok 'TV::Views::View';
}

my $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 10 );
isa_ok( $bounds, TRect );

# Test the clearEvent method
subtest 'clearEvent method' => sub {
  my $view  = TView->new( bounds => $bounds );
  my $event = TEvent->new();
  $view->clearEvent( $event );
  is(
    $event->{what}, evNothing,
    'event.what is set correctly after clearEvent'
  );
  isa_ok(
    $event->{message}, 'MessageEvent',
    'event.message is set correctly after clearEvent'
  );
}; #/ 'clearEvent method' => sub

# Test the eventAvail method
subtest 'eventAvail method' => sub {
  my $view = TView->new( bounds => $bounds );
  ok( !$view->eventAvail(), 'eventAvail method returns false' );
};

# Test the getEvent method
subtest 'getEvent method' => sub {
  my $view  = TView->new( bounds => $bounds );
  my $event = TEvent->new();
  lives_ok { $view->getEvent( $event ) }
    'getEvent method executed without errors' ;
};

# Test the handleEvent method
subtest 'handleEvent method' => sub {
  my $view  = TView->new( bounds => $bounds );
  my $event = TEvent->new( what => evMouseDown );
  lives_ok { $view->handleEvent( $event ) }
    'handleEvent method executed without errors';
};

# Test the putEvent method
subtest 'putEvent method' => sub {
  my $view  = TView->new( bounds => $bounds );
  my $event = TEvent->new();
  lives_ok { $view->putEvent( $event ) }
    'putEvent method executed without errors';
};

done_testing;
