=pod

=head1 DECRIPTION

The following test cases of class I<TGroup> cover the methods I<draw>, 
I<redraw>, I<lock>, I<unlock>, I<resetCursor>, I<endModal>, I<eventError>, 
I<getHelpCtx>, I<valid>, I<freeBuffer> and I<getBuffer>.

=cut

use strict;
use warnings;

use Test::More tests => 31;
use Test::Exception;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Drivers::Event';
  use_ok 'TV::Views::Const', qw(
    CM_RELEASED_FOCUS
    HC_NO_CONTEXT
    SF_EXPOSED
  );
  use_ok 'TV::Views::Group';
}

# Test object creations
my $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 10 );
isa_ok( $bounds, TRect, 'Object is of class TRect' );

my $event = TEvent->new();
isa_ok( $event, TEvent, 'Object is of class TEvent' );

# my $view = MyView->new( bounds => $bounds );
# isa_ok( $view, TView, 'Object is of class TView' );

my $group = TGroup->new( bounds => $bounds );
isa_ok( $group, TGroup, 'Object is of class TGroup' );

# Test draw method
can_ok( $group, 'draw' );
lives_ok { $group->draw() } 'draw works correctly';

# Test redraw method
can_ok( $group, 'redraw' );
lives_ok { $group->redraw() } 'redraw works correctly';

# Test getBuffer method
$group->{state} |= SF_EXPOSED;
$group->{size}{x} = $group->{size}{y} = 1;
can_ok( $group, 'getBuffer' );
lives_ok { $group->getBuffer() } 'getBuffer works correctly';

# Test lock and getBuffer method
can_ok( $group, 'lock' );
lives_ok { $group->lock() } 'lock works correctly';
ok( $group->{lockFlag}, 'lockFlag is not 0' );

# Test freeBuffer method
can_ok( $group, 'freeBuffer' );
lives_ok { $group->freeBuffer() } 'freeBuffer works correctly';

# Test unlock and drawView method
can_ok( $group, 'unlock' );
lives_ok { $group->unlock() } 'unlock works correctly';
ok( !$group->{lockFlag}, 'lockFlag is 0' );

# Test resetCursor method
can_ok( $group, 'resetCursor' );
lives_ok { $group->resetCursor() } 'resetCursor works correctly';

# Test endModal method
can_ok( $group, 'endModal' );
lives_ok { $group->endModal( 1 ) } 'endModal works correctly';

# Test eventError method
can_ok( $group, 'eventError' );
lives_ok { $group->eventError( $event ) } 'eventError works correctly';

# Test getHelpCtx method
can_ok( $group, 'getHelpCtx' );
is( $group->getHelpCtx(), HC_NO_CONTEXT, 'getHelpCtx returns correct value' );

# Test valid method
can_ok( $group, 'valid' );
is( $group->valid( CM_RELEASED_FOCUS ), 1, 'valid returns correct value' );

done_testing;
