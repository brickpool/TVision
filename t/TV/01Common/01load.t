#!perl

use strict;
use warnings;

use Test::More qw( no_plan );

BEGIN {
  use_ok 'TV::Const';
  use_ok 'TV::toolkit';
  use_ok 'slots::less';
  use_ok 'UNIVERSAL::Object::LOP';
  use_ok 'fields::LOP';
}
