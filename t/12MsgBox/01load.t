#!perl

use strict;
use warnings;

use Test::More qw( no_plan );

BEGIN {
  use_ok 'TV::MsgBox::Const', qw( mfOKButton );
  use_ok 'TV::MsgBox::MsgBoxText', qw( messageBox );
}
