use 5.014;
use warnings;
use Test::More;

use TurboVision::Objects::Rect;
use TurboVision::Objects::Types qw( TRect );

use TurboVision::Views::View;
use TurboVision::Views::Types qw( TView );
use TurboVision::Views::Const qw( :cmXXXX );

my $v = TView->init( TRect->new( 0, 1, 80, 25-1 ) );
isa_ok(
  $v,
  TView->class(),
);

ok(
  !defined $v->next(),
  'TView->next'
);

ok (
  $v->command_enabled(1),
  'TView->command_enabled'
);

$v->disable_commands([1]),
ok (
  !$v->command_enabled(1),
  'TView->disable_commands'
);

ok (
  !$v->command_enabled(CM_ZOOM),
  '! TView->command_enabled'
);

$v->enable_commands([CM_ZOOM]),
ok (
  $v->command_enabled(CM_ZOOM),
  'TView->enable_commands'
);

done_testing;
