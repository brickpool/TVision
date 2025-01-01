#!perl

use strict;
use warnings;

use Test::More qw( no_plan );

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Views::Const';
  use_ok 'TV::Views::CommandSet';
  use_ok 'TV::Views::Palette';
  use_ok 'TV::Views::View::Cursor';
  use_ok 'TV::Views::View::Exposed';
  use_ok 'TV::Views::View::Write';
  use_ok 'TV::Views::View';
  use_ok 'TV::Views::Group';
}

isa_ok( TCommandSet->new(), TCommandSet );
isa_ok( TPalette->new(), TPalette );
isa_ok( TView->new( bounds => TRect->new() ), TView );
isa_ok( TGroup->new( bounds => TRect->new() ), TGroup );
