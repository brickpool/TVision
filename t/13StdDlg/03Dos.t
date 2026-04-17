use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TV::StdDlg::Dos', qw(
    _dos_findfirst
    _dos_findnext
  );
}

# Test _dos_findfirst and _dos_findnext
subtest '_dos_findfirst and _dos_findnext' => sub {
  my $finfo = find_t->new();
  my $result = _dos_findfirst( '.\\*', 0x00, $finfo );    # Find all files
  is( $result, 0, '_dos_findfirst should succeed' );

  if ( $result == 0 ) {
    ok( defined $finfo->name, 'File name should be defined' );
    note( 'Found file: ' . $finfo->name );

    # Test _dos_findnext
    while ( _dos_findnext( $finfo ) == 0 ) {
      ok( defined $finfo->name, 'Next file name should be defined' );
      note( 'Next file: ' . $finfo->name );
      last if $finfo->name =~ /^\.\.?$/;  # Avoid infinite loop in test
    }
  }
};

subtest 'TV::StdDlg::FindFirstRec::Win32' => sub {
  if ( $^O ne 'MSWin32' ) {
    skip( 'This test is only relevant on Windows', 3 );
    return;
  }
  use_ok 'TV::StdDlg::FindFirstRec::Win32';
  dies_ok { TV::StdDlg::FindFirstRec::Win32->CP_UTF8() }
    'CP_UTF8 should not be visible outside of the module';
  dies_ok { TV::StdDlg::FindFirstRec::Win32->dwFileAttributes() }
    'dwFileAttributes should not be visible outside of the module';
};

done_testing();
