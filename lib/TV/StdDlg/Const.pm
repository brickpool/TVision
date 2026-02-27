package TV::StdDlg::Const;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (
  cmXXXX => [qw(
		cmFileOpen
		cmFileReplace
		cmFileClear
		cmFileInit
		cmChangeDir
		cmRevert
		cmDirSelection

    cmFileFocused
    cmFileDoubleClicked
  )],
);

# add all the other %EXPORT_TAGS ":class" tags to the ":all" class and
# @EXPORT_OK, deleting duplicates
{
  my %seen;
  push
    @EXPORT_OK,
      grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}}
        foreach keys %EXPORT_TAGS;
  push
    @{$EXPORT_TAGS{all}},
      @EXPORT_OK;
}

# Commands

use constant {
  cmFileOpen     => 1001,    # Returned from TFileDialog when Open pressed
  cmFileReplace  => 1002,    # Returned from TFileDialog when Replace pressed
  cmFileClear    => 1003,    # Returned from TFileDialog when Clear pressed
  cmFileInit     => 1004,    # Used by TFileDialog internally
  cmChangeDir    => 1005,
  cmRevert       => 1006,    # Used by TChDirDialog internally
  cmDirSelection => 1007,    # ! New event - Used by TChDirDialog internally ..
                             # .. and TDirListbox externally
};

# Messages

use constant {
  cmFileFocused       => 102,    # A new file was focused in the TFileList
  cmFileDoubleClicked => 103,    # A file was selected in the TFileList
};

1
