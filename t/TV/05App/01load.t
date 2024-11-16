use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TV::App::DeskInit';
}

isa_ok( TDeskInit->new( sub { } ), TDeskInit );

done_testing;
