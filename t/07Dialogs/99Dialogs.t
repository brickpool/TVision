#!perl

use strict;
use warnings;

use Test::More tests => 6;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Dialogs';
}

is( hotKey('~K~ey'), 'K', 'Util successfully imported' );
isa_ok( new_TDialog( TRect->new(), '' ), TDialog );
isa_ok( new_TButton( TRect->new(), 'Title', 0, 0 ), TButton );
isa_ok( new_TStaticText( TRect->new(), 'Text' ), TStaticText );

done_testing;
