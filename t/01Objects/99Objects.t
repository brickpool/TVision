use 5.014;
use warnings;

use Test::More import => [qw( !fail )];   # don't import fail() from Test::More

BEGIN {
  use_ok 'TurboVision::Objects';
}

isa_ok(
  TPoint->new(x => 1, y => 2),
  TPoint->class
);

isa_ok(
  TRect->init(1, 2, 3, 4),
  TRect->class
);

is(
  ST_ERROR,
  -1,
  'stXXXX constants'
);

isa_ok(
  TStream->init(),
  TStream->class
);

isa_ok(
  TDosStream->init('test.bin', ST_CREATE),
  TDosStream->class
);

isa_ok(
  TBufStream->init('test.bin', ST_OPEN, 0),
  TBufStream->class
);

isa_ok(
  TMemoryStream->init(),
  TMemoryStream->class
);

is(
  CO_OVERFLOW,
  -2,
  'coXXXX constants'
);

isa_ok(
  TCollection->init(),
  TCollection->class
);

isa_ok(
  TSortedCollection->init(),
  TSortedCollection->class
);

isa_ok(
  TStringCollection->init(),
  TStringCollection->class
);

isa_ok(
  TResourceCollection->init(),
  TResourceCollection->class
);

isa_ok(
  TResourceFile->init( TMemoryStream->init() ),
  TResourceFile->class()
);

isa_ok(
  TStrListMaker->init(256, 1),
  TStrListMaker->class
);

isa_ok(
  TStringList->init(),
  TStringList->class
);

done_testing;
