use 5.014;
use warnings;
use Test::More;

BEGIN {
  require_ok 'TurboVision::Objects::MemoryStream';
  require_ok 'TurboVision::Objects::StringCollection';
}

use TurboVision::Objects::Const qw( ST_OK );
use TurboVision::Objects::MemoryStream;
use TurboVision::Objects::StringCollection;
use TurboVision::Objects::Types qw(
  TMemoryStream
  TStringCollection
);

my $stream = TMemoryStream->init();
isa_ok(
  $stream,
  TMemoryStream->class,
);

my $col = TStringCollection->init();
isa_ok(
  $col,
  TStringCollection->class,
);

$col->put_item($stream, \'b');
$stream->seek(0);
is(
  $stream->status,
  ST_OK,
  'TMemoryStream->status'
);

$col->insert($col->get_item($stream));
$col->insert(\'d');
$col->insert(\'bccd');
$col->insert(\'e');
$col->insert(\'eff');
$col->insert(\'aa');

my $sum = '';
$col->for_each( sub { $sum .= $$_ } );

like(
  $sum,
  qr/\A aabbccddeeff \z/xms,
  'TStringCollection->index_of & insert & key_of & search'
);

done_testing;
