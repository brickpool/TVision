use 5.014;
use warnings;
use Test::More;

use TurboVision::Objects::Const qw( :stXXXX );
use TurboVision::Objects::Types qw( TDosStream is_TDosStream );

use_ok 'TurboVision::Objects::DosStream';

my $obj = TDosStream->init('test.bin', ST_CREATE);
isa_ok(
  $obj,
  TDosStream->class
);

ok(
  is_TDosStream($obj),
  'is_TDosStream'
);

$obj->write_str('abcd');
$obj->write_str('123');
is(
  $obj->status,
  ST_OK,
  'TDosStream->write_str'
);

undef $obj;
$obj = TDosStream->init('test.bin', ST_OPEN);
isa_ok(
  $obj,
  TDosStream->class
);

$obj->seek(5);
is(
  $obj->status,
  ST_OK,
  'TDosStream->seek'
);  
  
like(
  $obj->read_str(),
  qr/123/,
  'TDosStream->read_str',
);

$obj->seek(5);
$obj->truncate();
is(
  $obj->get_pos,
  5,
  'TDosStream->seek & truncate & get_pos'
);  

$obj->seek(0);
is(
  $obj->get_size,
  5,
  'TDosStream->seek & get_size'
);

done_testing;
