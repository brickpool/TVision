#!perl

use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Dialogs';
}

is( hotKey('~K~ey'), 'K', 'Util successfully imported' );
isa_ok( new_TDialog( TRect->new(), '' ), TDialog );
isa_ok( new_TButton( TRect->new(), 'Title', 0, 0 ), TButton );

done_testing;
