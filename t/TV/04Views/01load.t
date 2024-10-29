use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TV::Views::Const';
  use_ok 'TV::Views::CommandSet';
  use_ok 'TV::Views::Palette';
  use_ok 'TV::Views::View';
}

isa_ok( TCommandSet->new(), TCommandSet );
isa_ok( TPalette->new(), TPalette );

done_testing;
