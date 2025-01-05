#!perl

use strict;
use warnings;

use Test::More qw( no_plan );

BEGIN {
  use_ok 'slots::less';
  use_ok 'TV::toolkit::LOP::UNIVERSAL::Object';
  use_ok 'TV::toolkit::LOP::Class::Fields';
  use_ok 'TV::toolkit::LOP::Class::Tiny';
  use_ok 'TV::toolkit::LOP::Moo';
  use_ok 'TV::toolkit::LOP::Moose';
  use_ok 'TV::toolkit::LOP';
  use_ok 'TV::toolkit';
  use_ok 'TV::decorators';
}
