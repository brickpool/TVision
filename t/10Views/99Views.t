#!perl

use strict;
use warnings;

use Test::More tests => 12;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Views';
}

is( cmValid, 0, 'cmValid is 0' );
isa_ok( new_TCommandSet(),                  TCommandSet );
isa_ok( new_TPalette( '', 0 ),              TPalette    );
isa_ok( new_TView( TRect->new() ),          TView       );
isa_ok( new_TGroup( TRect->new() ),         TGroup      );
isa_ok( new_TFrame( TRect->new() ),         TFrame      );
isa_ok( new_TScrollBar( TRect->new() ),     TScrollBar  );
isa_ok( new_TWindowInit( sub { } ),         TWindowInit );
isa_ok( new_TWindow( TRect->new(), '', 0 ), TWindow     );
ok( exists &message, 'message() exists' );

done_testing;
