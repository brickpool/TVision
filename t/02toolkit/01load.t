use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TV::toolkit::boolean';
  use_ok 'TV::toolkit::Params';
  use_ok 'TV::toolkit::Types';
  if ( eval { require UNIVERSAL::Object } ) {
    use_ok 'TV::toolkit::UO::Base';
    use_ok 'TV::toolkit::UO::Antlers';
  }
  use_ok 'TV::toolkit';
}

note $TV::toolkit::name;

done_testing();
