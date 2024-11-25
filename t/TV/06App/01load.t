#!perl

use strict;
use warnings;

use Test::More qw( no_plan );

BEGIN {
  use_ok 'TV::App::Const';
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::App::Background';
  use_ok 'TV::App::DeskInit';
  use_ok 'TV::App::DeskTop';
  use_ok 'TV::App::ProgInit';
  use_ok 'TV::App::Program';
}

isa_ok(
  TBackground->new( bounds => TRect->new(), aPattern => '#' ),
  TBackground
);
isa_ok( TDeskInit->new( cBackground => sub { } ), TDeskInit );
isa_ok( TDeskTop->new( bounds => TRect->new() ),  TDeskTop );
isa_ok( TProgInit->new(
  cStatusLine => sub { },
  cMenuBar    => sub { },
  cDeskTop    => sub { },
), TProgInit );
