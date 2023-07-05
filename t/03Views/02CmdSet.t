use 5.014;
use warnings;
use Test::More;
no if $] >= 5.018, warnings => 'experimental::smartmatch';

use TurboVision::Views::Const qw( CM_VALID CM_QUIT CM_CLOSE );
use TurboVision::Views::Types qw( TCommandSet );

use_ok 'TurboVision::Views::CommandSet';

my $set = TCommandSet->new();
isa_ok(
  $set,
  'TurboVision::Views::CommandSet',
  'TCommandSet->new()'
);

ok (
  $set->is_empty,
  'TCommandSet->new->is_empty'
);

$set = TCommandSet->new(cmds => []);
isa_ok(
  $set,
  'TurboVision::Views::CommandSet',
  'TCommandSet->new(cmds => [])'
);

$set = TCommandSet->init([CM_QUIT]);
isa_ok(
  $set,
  'TurboVision::Views::CommandSet',
  'TCommandSet->init($set)'
);

ok (
  $set->contains(CM_QUIT) && !$set->contains(CM_CLOSE),
  '$set->contains'
);

$set->enable_cmd(CM_CLOSE);
ok (
  $set->contains(CM_CLOSE),
  '$set->enable_cmd($cmd)'
);

$set->disable_cmd(CM_CLOSE);
ok (
  $set->contains(CM_QUIT) && !$set->contains(CM_CLOSE),
  '$set->disable_cmd($cmd)'
);

$set->enable_cmd(CM_CLOSE);
ok (
  $set->contains(CM_CLOSE),
  '$set->enable_cmd($cmd)'
);

$set = TCommandSet->init();
$set += [CM_VALID];
ok (
  !$set->is_empty,
  'TCommandSet->init() && $set->_include($cmd) && not $set->is_empty'
);

my $copy = $set;
$set -= [CM_VALID];
ok (
  $set->is_empty,
  '$set->_exclude($cmd) && $set->is_empty'
);

cmp_ok(
  $set, '!=', $copy,
  '$set->_clone && $set->_not_equal($copy)'
);

$set += [CM_VALID];
cmp_ok(
  $set, '==', $copy,
  '$set->_include($set) && $set->_equal($copy)'
);

$set = TCommandSet->init([CM_QUIT]);
$copy = TCommandSet->init([CM_VALID, CM_QUIT]);
$copy = $copy * $set;
cmp_ok(
  $set, '==', $copy,
  '$set->_intersect($copy)'
);

$set += [CM_VALID];
$copy = $copy + TCommandSet->init([CM_VALID]);
cmp_ok(
  $set, '==', $copy,
  '$set->_union($copy)'
);

ok (
  CM_QUIT ~~ $set,
  '$set->_matching($cmd)'
);

$set = [] * $set ;
ok (
  $set->is_empty,
  '$set->_intersect([]) & $set->is_empty'
);

done_testing;
