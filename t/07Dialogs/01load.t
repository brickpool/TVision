#!perl

use strict;
use warnings;

use Test::More qw( no_plan );

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Dialogs::Const', qw( bfDefault ); 
  use_ok 'TV::Dialogs::Util', qw( hotKey );
  use_ok 'TV::Dialogs::Dialog';
  use_ok 'TV::Dialogs::Button';
  use_ok 'TV::Dialogs::History::HistList';
}

isa_ok( TDialog->new( bounds => TRect->new(), title => 'title' ), TDialog );
isa_ok( TButton->new( bounds => TRect->new(), title => 'title', command => 0,
  flags => bfDefault ), TButton );
