use 5.014;
use warnings;
use Test::More;

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

$set = TCommandSet->new( TCommandSet->new() );
isa_ok(
  $set,
  'TurboVision::Views::CommandSet',
  'TCommandSet->new( TCommandSet->new() )'
);

$set = TCommandSet->new( [CM_QUIT] );
isa_ok(
  $set,
  'TurboVision::Views::CommandSet',
  'TCommandSet->new( $set )'
);

ok (
  $set->enabled( CM_QUIT ) && !$set->enabled( CM_CLOSE ),
  'TCommandSet->enabled'
);

$set->enable_cmd( CM_CLOSE );
ok (
  $set->enabled( CM_CLOSE ),
  'TCommandSet->enable_cmd( $cmd )'
);

$set->disable_cmd( TCommandSet->new( [CM_CLOSE] ) );
ok (
  $set->enabled( CM_QUIT ) && !$set->enabled( CM_CLOSE ),
  'TCommandSet->disable_cmd( TCommandSet->new( $set ) )'
);

$set->enable_cmd( [CM_CLOSE] );
ok (
  $set->enabled( CM_CLOSE ),
  'TCommandSet->enable_cmd( $set )'
);

$set->disable_cmd( $set );
ok (
  $set->is_empty,
  'TCommandSet->disable_cmd( $self )->is_empty'
);

$set += CM_VALID;
$set += [CM_CLOSE];
$set += TCommandSet->new( [CM_QUIT] );
ok (
  !$set->is_empty,
  'not TCommandSet->_enable( $set )->is_empty'
);

my $copy = $set;
$set -= $set;
ok (
  $set->is_empty,
  'TCommandSet->_disable( $self )->is_empty'
);

cmp_ok(
  $copy, '!=', $set,
  'TCommandSet->_clone && _not_equal( $set1, $set2 )'
);

$set |= CM_VALID;
$set |= [CM_CLOSE];
$set |= TCommandSet->new( [CM_QUIT] );
cmp_ok(
  $copy, '==', $set,
  'TCommandSet->_union( $set ) && _equal( $set1, $set2 )'
);

$set &= [CM_QUIT, CM_CLOSE];
$copy = $copy & TCommandSet->new( [CM_QUIT, CM_CLOSE] );
cmp_ok(
  $set, '==', $copy,
  'TCommandSet->_intersect( $set ) && _and( $set1, $set2 )'
);

$set |= CM_VALID;
$copy = $copy | TCommandSet->new( [CM_VALID] );
cmp_ok(
  $set, '==', $copy,
  '_or( $set1, $set2 )'
);

done_testing;
