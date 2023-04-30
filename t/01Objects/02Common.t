use 5.014;
use warnings;
use Test::More import => [qw( !fail )];   # don't import fail() from Test::More
use English;
use Scalar::Util qw( isweak refaddr );
use Devel::Refcount qw( refcount );

require_ok 'TurboVision::Objects::Common';

use TurboVision::Objects::Common qw( :all );
use English qw( EVAL_ERROR );

#--------------
note 'Typecast';
#--------------
is(   byte->size,        1,       'byte->size'      );
like( byte->type,        qr/^C$/, 'byte->type'      );
is(   byte(0x102)->cast, 2,       'byte(INT)->cast' );
is(
  byte( byte(3)->pack() )->unpack,
  3,
  'byte->pack & unpack'
);

is(   word->size,          2,       'word->size'      );
like( word->type,          qr/^v$/, 'word->type'      );
is(   word(0x10003)->cast, 3,       'word(INT)->cast' );
is(
  word( word(4)->pack() )->unpack,
  4,
  'word->pack & unpack'
);

my $longint = longint(0x8000_0000)->cast;
is(  $longint,       -2**31,        'longint(INT)->cast'  );
is(   longint->size,      4,        'longint->size'       );
like( longint->type,      qr/^V!$/, 'longint->type'       );
is(   longint(-1)->cast, -1,        'longint(-1)->cast'   );
is(
  longint( longint(5)->pack() )->unpack,
  5,
  'longint->pack & unpack'
);

#------------
note 'Tools';
#------------
is( long_div(5,   2),  2, 'long_div +'  );
is( long_div(-5,  2), -2, 'long_div -'  );
is( long_div(-5, -2),  2, 'long_div --' );

is( long_mul(5, 2), 10, 'long_mul' );

is( word_rec( 0x0203   ),     0x0203, 'word_rec'    );
is( word_rec( 0x0203   )->hi, 2,      'word_rec hi' );
is( word_rec( 0x0203   )->lo, 3,      'word_rec lo' );
is( word_rec( 0xffff+2 ),     1,      'word_rec +2' );

is( long_rec( 0x80000001   ),     0x80000001, 'long_rec'    );
is( long_rec( 0x80000001   )->lo, 1,          'long_rec lo' );
is( long_rec( 0x80000001   )->hi, 0x8000,     'long_rec hi' );
is( long_rec( 0xffffffff+1 )->hi, 0,          'long_rec +1' );
is( long_rec( 0xffffffff+2 ),     1,          'long_rec +2' );

my $p = \'string';
is( ptr_rec($p), refaddr($p), 'ptr_rec' );
like(
  sprintf( '%x'.           ':'           .'%04x',
           ptr_rec($p)->seg , ptr_rec($p)->ofs ),
  qr{\A    \p{PosixXDigit}+ : \p{PosixXDigit}{4} \z}xms,
  'ptr_rec seg:ofs'
);

#--------------
note 'Routines';
#--------------
eval { abstract(); 1 };
like( $EVAL_ERROR, qr/abstract method/, 'abstract' );

eval { fail(); 1 };
like( $EVAL_ERROR, qr/Call to/, 'fail' );

cmp_ok( ref( new_str('Test') ), 'eq', 'SCALAR', 'new_str ref'   );
ok    ( !defined( new_str('') ),                'new_str undef' );

is( refcount($p), 2, 'refcount: 2'     );
dispose_str($p);
ok( isweak($p),      'dispose_str ref' );
is( refcount($p), 1, 'refcount: 1'     );
undef $p;
ok( eval { dispose_str($p); 1 },    'dispose_str undef' );
ok( eval { register_objects(); 1 }, 'register_objects'  );

done_testing;
