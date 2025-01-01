=pod

=head1 DESCRIPTION
 
These test cases cover the creation of the object I<TGroup>, the setting and 
retrieval of some fields as well as the behavior of the methods I<setState>, 
I<handleEvent>, I<drawSubViews>, I<changeBounds>, I<dataSize>, I<getData> 
and I<setData>. 

=cut

use strict;
use warnings;

use Test::More tests => 25;
use Test::Exception;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Drivers::Event';
  use_ok 'TV::Views::Const', qw( 
    cmCancel
    sfActive
  );
  use_ok 'TV::Views::View';
  use_ok 'TV::Views::Group';
}

# Mocking TView for testing purposes
BEGIN {
  package MyView;
  use TV::toolkit;
  extends 'TV::Views::View';
  sub dataSize { 1 }
  $INC{"MyView.pm"} = 1;
}

use_ok 'MyView';

# Test object creations
my $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 10 );
isa_ok( $bounds, TRect, 'Object is of class TRect' );

my $event = TEvent->new();
isa_ok( $event, TEvent, 'Object is of class TEvent' );

my $view = MyView->new( bounds => $bounds );
isa_ok( $view, TView, 'Object is of class TView' );

my $group = TGroup->new( bounds => $bounds );
isa_ok( $group, TGroup, 'Object is of class TGroup' );

# Test setState method
can_ok( $group, 'setState' );
lives_ok { $group->setState( sfActive, !!1 ) }
  'setState works correctly';

# Test handleEvent method
can_ok( $group, 'handleEvent' );
lives_ok { $group->handleEvent( $event ) } 'handleEvent works correctly';

# Test drawSubViews method
can_ok( $group, 'drawSubViews' );
lives_ok { $group->drawSubViews( $view, undef ) }
  'drawSubViews works correctly';

# Test changeBounds method
can_ok( $group, 'changeBounds' );
lives_ok { $group->changeBounds( $bounds ) } 'changeBounds works correctly';

# Test setData method
can_ok( $group, 'setData' );
$group->insertView( $view, undef );
is( $group->last(), $view, 'insertView sets last correctly' );
my @rec = ( 0 );
lives_ok { $group->setData( \@rec ) } 'setData works correctly';

# Test dataSize method
can_ok( $group, 'dataSize' );
is( $group->dataSize(), 1, 'dataSize returns correct value' );

# Test getData method
can_ok( $group, 'getData' );
lives_ok { $group->getData( \@rec ) } 'getData works correctly';

done_testing;
