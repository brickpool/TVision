use strict;
use warnings;

use Test::More;


BEGIN {
  if ( eval { require UNIVERSAL::Object } ) {
    use_ok 'slots::less';
    use_ok 'TV::toolkit::LOP::UNIVERSAL::Object';
  }
  use_ok 'TV::toolkit::LOP::Class::Fields';
  if ( eval { require Class::Tiny } ) {
    use_ok 'TV::toolkit::LOP::Class::Tiny';
  }
  if ( eval { require Moo } ) {
    use_ok 'TV::toolkit::LOP::Moo';
  }
  if ( eval { require Moose } ) {
    use_ok 'TV::toolkit::LOP::Moose';
  }
  use_ok 'TV::toolkit::LOP';
  use_ok 'TV::toolkit::decorators';
  use_ok 'TV::toolkit';
}

done_testing();
