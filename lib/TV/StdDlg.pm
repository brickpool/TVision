package TV::StdDlg;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TV::StdDlg::Const;
use TV::StdDlg::SortedListBox;

sub import {
  my $target = caller;
  TV::StdDlg::Const->import::into( $target, qw( :all ) );
  TV::StdDlg::SortedListBox->import::into( $target );
}

sub unimport {
  my $caller = caller;
  TV::StdDlg::Const->unimport::out_of( $caller );
  TV::StdDlg::SortedListBox->unimport::out_of( $caller );
}

1
