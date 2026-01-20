#!perl

use strict;
use warnings;

use Test::More qw( no_plan );

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Dialogs::Const';
  use_ok 'TV::Dialogs::Dialog';
  use_ok 'TV::Dialogs::History::HistList';
}

isa_ok( TDialog->new( bounds => TRect->new(), title => 'title' ), TDialog );
