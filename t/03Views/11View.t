use 5.014;
use warnings;
use Test::More;

use TurboVision::Objects::Rect;
use TurboVision::Objects::Types qw( TRect );

use TurboVision::Views::CommandSet;
use TurboVision::Views::Const qw( :cmXXXX );
use TurboVision::Views::Types qw(
  TView
  TCommandSet
);
use TurboVision::Views::View;

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

$v->disable_commands(TCommandSet->init([1])),
ok (
  !$v->command_enabled(1),
  'TView->disable_commands'
);

ok (
  !$v->command_enabled(CM_ZOOM),
  '! TView->command_enabled'
);

$v->enable_commands(TCommandSet->init([CM_ZOOM])),
ok (
  $v->command_enabled(CM_ZOOM),
  'TView->enable_commands'
);

done_testing;
