use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TV::App::Const';
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::App::Background';
  use_ok 'TV::App::DeskInit';
}

isa_ok( TDeskInit->new( sub { } ), TDeskInit );
isa_ok( 
  TBackground->new( bounds => TRect->new(), aPattern => '#' ),
	TBackground
);

done_testing;
