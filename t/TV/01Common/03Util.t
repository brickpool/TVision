use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
  require_ok 'fields';
  use_ok 'TV::Util';
}

is $TV::Util::toolkit, 'fields', 'Toolkit is fields';
ok TV::toolkit::fields(), 'TV::toolkit::fields is set to true';

done_testing;
