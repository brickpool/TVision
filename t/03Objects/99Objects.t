#!perl

use strict;
use warnings;

use Test::More tests => 9;

BEGIN {
  use_ok 'TV::Objects';
}

is( ccNotFound, -1, 'ccNotFound is -1' );
isa_ok( TObject->new(), TObject );
isa_ok( TPoint->new(), TPoint );
isa_ok( TRect->new(), TRect );
isa_ok( TNSCollection->new(), TNSCollection );
isa_ok( TNSSortedCollection->new(), TNSSortedCollection );
isa_ok( TCollection->new(), TCollection );
isa_ok( TSortedCollection->new(), TSortedCollection );

done_testing;
