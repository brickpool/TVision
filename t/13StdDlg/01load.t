use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::StdDlg::Const';
  use_ok 'TV::StdDlg::FindFirstRec';
  use_ok 'TV::StdDlg::Dos';               # incl. ffblk and find_t
  use_ok 'TV::StdDlg::Dir';
  use_ok 'TV::StdDlg::Util', qw( fexpand );
  use_ok 'TV::StdDlg::FileCollection';    # incl. TSearchRec
  use_ok 'TV::StdDlg::FileInputLine';
  use_ok 'TV::StdDlg::SortedListBox';
  use_ok 'TV::StdDlg::FileList';
  use_ok 'TV::StdDlg::FileInfoPane';
}

isa_ok( FindFirstRec->allocate( [], 0, '' ), FindFirstRec() );
isa_ok( ffblk->new(), 'ffblk' );
isa_ok( find_t->new(), 'find_t' );
isa_ok( TSearchRec->new(), 'TSearchRec' );
isa_ok( TFileCollection->new( limit => 0, delta => 0 ), TFileCollection );
isa_ok( TFileInputLine->new( bounds => TRect->new(), maxLen => 10, ), 
  TFileInputLine );
isa_ok( TSortedListBox->new( bounds => TRect->new(), numCols => 0, 
  vScrollBar => undef ), TSortedListBox() );
isa_ok( TFileList->new( bounds => TRect->new(), vScrollBar => undef ), 
  TFileList() );
isa_ok( TFileInfoPane->new( bounds => TRect->new() ), TFileInfoPane() );

done_testing();
