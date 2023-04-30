use 5.014;
use warnings;
use Test::More;

use TurboVision::Objects::Const qw( MAX_COLLECTION_SIZE );
use TurboVision::Objects::Types qw( TCollection );

use_ok 'TurboVision::Objects::Collection';

is(
  MAX_COLLECTION_SIZE,
  0xffff,
  'MAX_COLLECTION_SIZE'
);

my $obj = TCollection->init(6, 4);
isa_ok(
  $obj,
  TCollection->class
);

is(
  TCollection->init(-1, 1)->limit,
  0,
  'TCollection->set_limit'
);

eval { $obj->at(-1) };
like(
  $@,
  qr/index out of range/,
  'TCollection->error'
);

my ($a, $b, $c) = qw( a b c );
$obj->insert(\$a),
my $ref = $obj->at(0);
ok(
  $$ref eq 'a',
  'TCollection->at'
);

my $index = $obj->index_of($ref);
isnt(
  $index,
  -1,
  'TCollection->index_of'
);

$obj->insert(\$b),
$ref = $obj->first_that( sub { return $$_ eq 'b' } );
ok(
  $$ref eq 'b',
  'TCollection->first_that'
);

my $sum = 0;
$obj->for_each( sub { $sum += ord $$_ } );
is(
  $sum,
  195,
  'TCollection->for_each'
);

$obj->at_insert(1, \$c);
$obj->at_delete(0);
$ref = $obj->at(0);
ok(
  $$ref eq 'c',
  'TCollection->at_insert & at_delete'
);

$obj->at_put(0, \$c);
$ref = $obj->at(0);
ok(
  $$ref eq 'c',
  'TCollection->at_put'
);

{
  my $d = 'd';
  $obj->insert(\$d);
  $obj->free_item(\$d);
}
is(
  $obj->count,
  3,
  'TCollection->free_item'
);
$obj->pack();
is(
  $obj->count,
  2,
  'after TCollection->pack'
);

{
  my $d = 'd';
  $obj->insert(\$d);
}
$obj->at_free($obj->count-1);
is(
  $obj->count,
  2,
  'TCollection->at_free & count'
);

$ref = $obj->last_that( sub { defined } );
ok(
  $$ref eq 'b',
  'TCollection->last_that'
);

done_testing;
