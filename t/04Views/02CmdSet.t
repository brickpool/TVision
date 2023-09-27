use 5.014;
use warnings;
use Test::More tests => 22;

BEGIN {
  use_ok 'TurboVision::Views::Const',  qw( CM_VALID CM_QUIT CM_CLOSE );
  use_ok 'TurboVision::Views::Types', qw( TCommandSet );
  use_ok 'TurboVision::Views::CommandSet';
}

{
  no strict 'subs';

  my $new = TCommandSet->new();
  isa_ok(
    $new,
    TCommandSet->class,
    'TCommandSet->new()'
  );

  ok (
    $new->is_empty,
    'TCommandSet->is_empty'
  );

  $new = TCommandSet->new(cmds => []);
  isa_ok(
    $new,
    TCommandSet->class,
    'TCommandSet->new(cmds => [])'
  );
  
  my $init = TCommandSet->init([CM_QUIT]);
  isa_ok($init, TCommandSet->class);
  isa_ok(
    $init,
    'TurboVision::Views::CommandSet',
    'TCommandSet->init'
  );
  
  ok (
    $init->contains(CM_QUIT) && !$init->contains(CM_CLOSE),
    'TCommandSet->contains'
  );
  
  $init->enable_cmd(CM_CLOSE);
  ok (
    $init->contains(CM_CLOSE),
    'TCommandSet->enable_cmd'
  );
  
  $init->disable_cmd(CM_CLOSE);
  ok (
    $init->contains(CM_QUIT) && !$init->contains(CM_CLOSE),
    'TCommandSet->disable_cmd'
  );
  
  $init->enable_cmd(CM_CLOSE);
  ok (
    $init->contains(CM_CLOSE),
    'TCommandSet->enable_cmd'
  );
  
  $init = TCommandSet->init();
  isa_ok($init, TCommandSet->class);
  $init += [CM_VALID];
  ok (
    !$init->is_empty,
    'TCommandSet->init && TCommandSet->_include && not $set->is_empty'
  );
  
  my $copy = $init;
  $init -= [CM_VALID];
  ok (
    $init->is_empty,
    'TCommandSet->_exclude && TCommandSet->is_empty'
  );
  
  cmp_ok(
    $init, '!=', $copy,
    'TCommandSet->_clone && TCommandSet->_not_equal'
  );
  
  $init += [CM_VALID];
  cmp_ok(
    $init, '==', $copy,
    'TCommandSet->_include && TCommandSet->_equal'
  );
  
  $init = TCommandSet->init([CM_QUIT]);
  my $set = TCommandSet->init([CM_VALID, CM_QUIT]);
  isa_ok($set, TCommandSet->class);
  $set = $set * $init;
  cmp_ok(
    $init, '==', $set,
    'TCommandSet->_intersect'
  );
  
  $init += [CM_VALID];
  $set = $set + TCommandSet->init([CM_VALID]);
  cmp_ok(
    $init, '==', $set,
    'TCommandSet->_union'
  );
  
  {
    no if $] >= 5.018, warnings => 'experimental::smartmatch';
    ok (
      [CM_QUIT, CM_VALID] ~~ $init,
      'TCommandSet->_matching'
    );
  }
  
  $set = [] * $set ;
  ok (
    $set->is_empty,
    'TCommandSet->_intersect & TCommandSet->is_empty'
  );
}

done_testing;
