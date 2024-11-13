=pod

=head1 DECRIPTION

The following test cases of class I<TGroup> cover the methods I<insertView>, 
I<remove>, I<removeView>, I<resetCurrent>, I<setCurrent>, I<selectNext>, 
I<firstThat>, I<focusNext>, I<forEach>, I<insert>, I<insertBefore>, I<current>, 
I<at>, I<firstMatch>, I<indexOf> and I<first>.

=cut

use strict;
use warnings;

use Test::More tests => 40;
use Test::Exception;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Views::Const', qw( CM_CANCEL );
  use_ok 'TV::Views::View';
  use_ok 'TV::Views::Group';
}

# Mocking TGroup for testing purposes
BEGIN {
  package MyGroup;
  require TV::Views::Group;
  use base 'TV::Views::Group';
  sub handleEvent { shift->{endState} = 100 }
  $INC{"MyGroup.pm"} = 1;
}

use_ok 'MyGroup';

my $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 10 );
isa_ok( $bounds, TRect );

# Test object creation
my $group = TGroup->new( bounds => $bounds );
isa_ok( $group, TGroup, 'Object is of class TGroup' );

# Test insertView method
can_ok( $group, 'insertView' );
my $view1 = TView->new( bounds => $bounds );
my $view2 = TView->new( bounds => $bounds );
$group->insertView( $view1, undef );
is( $group->last(), $view1,
	'insertView sets last correctly when Target is undef' );
$group->insertView( $view2, $view1 );
is( $view1->next(), $view2,
	'insertView sets next correctly when Target is defined' );

# Test remove method
can_ok( $group, 'remove' );
$group->remove( $view1 );
is( $view1->owner(), undef, 'remove sets owner to undef' );
is( $view1->next(),  undef, 'remove sets next to undef' );

# Test last clear
$group->last(undef);
is( $group->last(), undef, 'last(undef) sets last to undef' );

# Test removeView method
can_ok( $group, 'removeView' );
$group->insertView( $view1, undef );
$group->insertView( $view2, $view1 );
$group->removeView( $view1 );
is( $view2->next(), $view2, 'removeView removes the view correctly' );

# Test resetCurrent method
can_ok( $group, 'resetCurrent' );
lives_ok { $group->resetCurrent() }
  'resetCurrent works correctly';

# Test setCurrent method
can_ok( $group, 'setCurrent' );
$group->setCurrent( $view2, 1 );
is( $group->current(), $view2, 'setCurrent sets current correctly' );

# Test selectNext method
can_ok( $group, 'selectNext' );
lives_ok { $group->selectNext( 1 ) }
  'selectNext works correctly';

# Test firstThat method
can_ok( $group, 'firstThat' );
my $func = sub { return shift == $view2 };
is( $group->firstThat( $func, undef ), $view2,
	'firstThat returns the correct view' );

# Test focusNext method
can_ok( $group, 'focusNext' );
is( $group->focusNext( 1 ), 1, 'focusNext returns correct value' );

# Test forEach method
can_ok( $group, 'forEach' );
my $count = 0;
$group->forEach( sub { $count++ }, undef );
is( $count, 1, 'forEach iterates over all views' );

# Test insert method
can_ok( $group, 'insert' );
my $view3 = TView->new( bounds => $bounds );
$group->insert( $view3 );
is( $group->first(), $view3, 'insert sets first correctly' );

# Test insertBefore method
can_ok( $group, 'insertBefore' );
$group->insertBefore( $view2, $view1 );
is( $view1->next(), $view2, 'insertBefore sets next correctly' );

# Test current method
can_ok( $group, 'current' );
$group->current( $view1 );
is( $group->current(), $view1, 'current sets and gets current correctly' );

# Test at method
can_ok( $group, 'at' );
is( $group->at( 1 ), $group->last()->next(), 'at returns the correct view' );

# Test firstMatch method
can_ok( $group, 'firstMatch' );
is( $group->firstMatch( 0, 0 ), $group->last(), 
  'firstMatch returns the correct view' );

# Test indexOf and first method
can_ok( $group, 'indexOf', 'first' );
is( $group->indexOf( $group->first() ), 1,
  'indexOf returns the correct index' );

done_testing;
