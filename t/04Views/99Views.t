use 5.014;
use warnings;

use Test::More import => [qw( !fail )];   # don't import fail() from Test::More

BEGIN {
  use_ok 'TurboVision::Objects';
  use_ok 'TurboVision::Views';
}

#------------------
note 'random check';
#------------------

isa_ok( 
  $shadow_size, 
  TPoint->class,
  '$shadow_size',
);
is(
  $shadow_size->x, 
  2,
  '$shadow_size->x == 2'
);

my $set = TCommandSet->new();
isa_ok(
  $set,
  TCommandSet->class,
  'TCommandSet->new()'
);
ok (
  $set->is_empty,
  'TCommandSet->is_empty'
);

my $bounds = TRect->init(0,1,80,24);
isa_ok(
  $bounds, 
  TRect->class,
  'TRect->init'
);
my $view = TView->init($bounds);
isa_ok(
  $view, 
  TView->class,
  'TView->init'
);
is( 
  $view->size->y, 
  23,
  '$view->size->y == 23'
);

done_testing;
