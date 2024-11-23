use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TV::App::Const';
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::App::Background';
  use_ok 'TV::App::DeskInit';
  use_ok 'TV::App::DeskTop';
}

isa_ok(
  TBackground->new( bounds => TRect->new(), aPattern => '#' ),
  TBackground
);
isa_ok( TDeskInit->new( cBackground => sub { } ), TDeskInit );
isa_ok( TDeskTop->new( bounds => TRect->new() ),  TDeskTop );

done_testing;
