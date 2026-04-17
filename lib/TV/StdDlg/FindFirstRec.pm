package TV::StdDlg::FindFirstRec;
# ABSTRACT: A class implementing the behaviour of findfirst and findnext

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw( FindFirstRec );

# Code snippet taken from File::Spec
my %module = (
  MSWin32 => 'Win32',
);

my $module = $module{$^O} || 'Unix';

sub FindFirstRec() { "TV::StdDlg::FindFirstRec::$module" }

require "TV/StdDlg/FindFirstRec/$module.pm";
our @ISA = ( FindFirstRec );

1
