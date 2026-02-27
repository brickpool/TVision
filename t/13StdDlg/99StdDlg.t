use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::StdDlg';
}

isa_ok( new_TSortedListBox(TRect->new(), 0, undef ), TSortedListBox() );

done_testing();
