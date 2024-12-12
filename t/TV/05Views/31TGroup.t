=pod

=head1 DESCRIPTION

The following test cases of class I<TGroup> cover the methods I<new>, 
I<DEMOLISH>, I<shutDown>, I<execView>, I<execute> and I<awaken>.

=cut

use strict;
use warnings;

use Test::More tests => 17;
use Test::Exception;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Views::Const', qw( cmCancel );
  use_ok 'TV::Views::View';
  use_ok 'TV::Views::Group';
}

# Mocking TGroup for testing purposes
BEGIN {
  package MyGroup;
  require TV::Views::Group;
  use base 'TV::Views::Group';
  use slots::less;
  sub handleEvent { shift->{endState} = 100 }
  $INC{"MyGroup.pm"} = 1;
}

use_ok 'MyGroup';

my $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 10 );
isa_ok( $bounds, TRect );

# Test object creation
my $group = TGroup->new( bounds => $bounds );
isa_ok( $group, TGroup, 'Object is of class TGroup' );

# Test DEMOLISH method
can_ok( $group, 'DEMOLISH' );
lives_ok { $group->DEMOLISH() }
  'DEMOLISH method works correctly';

# Test shutDown method
can_ok( $group, 'shutDown' );
lives_ok { $group->shutDown() }
  'shutDown method works correctly';

# Test execView method
can_ok( $group, 'execView' );
my $view = TView->new( bounds => $bounds );
is( $group->execView( $view ), cmCancel, 'execView returns correct value' );

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
