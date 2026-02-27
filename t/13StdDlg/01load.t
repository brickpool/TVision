use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::StdDlg::Const';
  use_ok 'TV::StdDlg::SortedListBox';
}

isa_ok( TSortedListBox->new( bounds => TRect->new(), numCols => 0, 
  vScrollBar => undef ), TSortedListBox() );

done_testing();
