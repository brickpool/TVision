=pod

=head1 DECRIPTION

The following test cases of class I<TGroup> cover the methods I<new>, 
I<DESTROY>, I<shutDown>, I<execView>, I<execute> and I<awaken>.

=cut

use strict;
use warnings;

use Test::More tests => 17;
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

# Test DESTROY method
can_ok( $group, 'DESTROY' );
lives_ok { $group->DESTROY() }
  'DESTROY method works correctly';

# Test shutDown method
can_ok( $group, 'shutDown' );
lives_ok { $group->shutDown() }
  'shutDown method works correctly';

# Test execView method
can_ok( $group, 'execView' );
my $view = TView->new( bounds => $bounds );
is( $group->execView( $view ), CM_CANCEL, 'execView returns correct value' );

# Test execute method
$group = MyGroup->new( bounds => $bounds );
can_ok( $group, 'execute' );
is( $group->execute(), 100, 'execute returns correct value' );

# Test awaken method
$group = TGroup->new( bounds => $bounds );
can_ok( $group, 'awaken' );
lives_ok { $group->awaken() }
  'awaken method works correctly';

done_testing;
