use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Views::View::Cursor';
  use_ok 'TV::Views::View::Exposed';
  use_ok 'TV::Views::View::Write';
  use_ok 'TV::Views::View';
}

isa_ok( TView->new( bounds => TRect->new() ), TView );

done_testing();
