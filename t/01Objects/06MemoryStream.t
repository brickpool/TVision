use 5.014;
use warnings;
use Test::More;

use TurboVision::Objects::Const qw( ST_OK );
use TurboVision::Objects::Types qw( TMemoryStream is_TMemoryStream );

use_ok 'TurboVision::Objects::MemoryStream';

my $obj = TMemoryStream->init(6, 4);
isa_ok(
  $obj,
  TMemoryStream->class
);

ok(
  is_TMemoryStream($obj),
  'is_TMemoryStream'
);

$obj->str_write('WXYZabc');
$obj->str_write('987');
is(
  $obj->status,
  ST_OK,
  'TMemoryStream->str_write'
);

$obj->seek(9);
is(
  $obj->status,
  ST_OK,
  'TMemoryStream->seek'
);  
  
like(
  $obj->str_read(),
  qr/987/,
  'TMemoryStream->str_read',
);

$obj->seek(9);
is(
  $obj->position,
  $obj->get_pos,
  'TMemoryStream->seek & position'
);  

is(
  $obj->get_size,
  14,
  'TMemoryStream->get_size'
);  

is(
  $obj->size,
  $obj->get_size,
  'TMemoryStream->size'
);  

$obj->truncate();
is(
  $obj->get_pos,
  9,
  'TMemoryStream->truncate & get_pos'
);  

$obj->seek(0);
like(
  $obj->str_read(),
  qr/WXYZabc/,
  'TMemoryStream->seek & str_read',
);

is(
  $obj->get_pos,
  9,
  'TMemoryStream->get_pos'
);

done_testing;
