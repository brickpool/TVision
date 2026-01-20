#!perl

use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Dialogs';
}

isa_ok( new_TDialog( TRect->new(), '' ),  TDialog );

done_testing;
