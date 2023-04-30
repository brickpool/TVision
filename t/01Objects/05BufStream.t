use 5.014;
use warnings;
use Test::More;

use TurboVision::Objects::Const qw( :stXXXX );
use TurboVision::Objects::Types qw( TBufStream is_TBufStream );

use_ok 'TurboVision::Objects::BufStream';

my $obj = TBufStream->init('test.bin', ST_CREATE, 4);
isa_ok(
  $obj,
  TBufStream->class
);

ok(
  is_TBufStream($obj),
  'is_TBufStream'
);

$obj->write_str('ABC');
$obj->write_str('4567');
is(
  $obj->status,
  ST_OK,
  'TBufStream->write_str'
);

undef $obj;
$obj = TBufStream->init('test.bin', ST_OPEN, 4);
isa_ok(
  $obj,
  TBufStream->class
);

$obj->seek(4);
is(
  $obj->status,
  ST_OK,
  'TBufStream->seek'
);  
  
like(
  $obj->read_str(),
  qr/4567/,
  'TBufStream->read_str',
);

$obj->seek(4);
$obj->truncate();
is(
  $obj->get_pos,
  4,
  'TBufStream->seek & truncate & get_pos'
);  

$obj->seek(0);
is(
  $obj->get_size,
  4,
  'TBufStream->seek & get_size'
);

done_testing;
