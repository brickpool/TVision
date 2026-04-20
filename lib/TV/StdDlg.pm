package TV::StdDlg;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TV::StdDlg::Const;
use TV::StdDlg::Dir;
use TV::StdDlg::Dos;
use TV::StdDlg::Util;
use TV::StdDlg::FileCollection;
use TV::StdDlg::FileInputLine;
use TV::StdDlg::FileList;
use TV::StdDlg::SortedListBox;

sub import {
  my $target = caller;
  TV::StdDlg::Const->import::into( $target, qw( :all ) );
  TV::StdDlg::Dos->import::into( $target, qw( /\S+/ ) );
  TV::StdDlg::Dir->import::into( $target, qw( /\S+/ ) );
  TV::StdDlg::Util->import::into( $target, qw( /\S+/ ) );
  TV::StdDlg::FileCollection->import::into( $target );
  TV::StdDlg::FileInputLine->import::into( $target );
  TV::StdDlg::FileList->import::into( $target );
  TV::StdDlg::SortedListBox->import::into( $target );
}

sub unimport {
  my $caller = caller;
  TV::StdDlg::Const->unimport::out_of( $caller );
  TV::StdDlg::Dos->unimport::out_of( $caller );
  TV::StdDlg::Dir->unimport::out_of( $caller );
  TV::StdDlg::Util->unimport::out_of( $caller );
  TV::StdDlg::FileCollection->unimport::out_of( $caller );
  TV::StdDlg::FileInputLine->unimport::out_of( $caller );
  TV::StdDlg::FileList->unimport::out_of( $caller );
  TV::StdDlg::SortedListBox->unimport::out_of( $caller );
}

1
