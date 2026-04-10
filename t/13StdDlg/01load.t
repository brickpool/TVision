use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::StdDlg::Const';
  use_ok 'TV::StdDlg::FileCollection';    # incl. TSearchRec
  use_ok 'TV::StdDlg::SortedListBox';
}

isa_ok( TSearchRec->new(), 'TSearchRec' );
isa_ok( TFileCollection->new( limit => 0, delta => 0 ), TFileCollection );
isa_ok( TSortedListBox->new( bounds => TRect->new(), numCols => 0, 
  vScrollBar => undef ), TSortedListBox() );

done_testing();
