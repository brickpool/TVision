use 5.014;
use warnings;
use Test::More;

require_ok 'TurboVision::Objects::ResourceCollection';

use TurboVision::Objects::Const qw( ST_OK );
use TurboVision::Objects::MemoryStream;
use TurboVision::Objects::ResourceCollection;
use TurboVision::Objects::Types qw(
  TMemoryStream
  TResourceCollection
);

my $stream = TMemoryStream->init();
isa_ok(
  $stream,
  TMemoryStream->class
);

my $col = TResourceCollection->init();
isa_ok(
  $col,
  TResourceCollection->class
);

my $str = 'test';
my $put = {
  posn  => 0,
  size  => length($str) + 1,
  key   => $str,
};

$col->put_item($stream, $put);
is(
  $stream->status,
  ST_OK,
  'TResourceCollection->put_item & TStream->status'
);

$stream->seek(0);
my $get = $col->get_item($stream);
is(
  $stream->status,
  ST_OK,
  'TResourceCollection->get_item & TStream->seek & status'
);

is_deeply(
  $put,
  $get,
  'TResourceItem @put_item == TResourceItem @get_item'
);

done_testing;
