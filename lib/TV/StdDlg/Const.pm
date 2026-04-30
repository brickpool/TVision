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

  cpXXXX => [qw(
    cpInfoPane
  )],
 
  fdXXXX => [qw(
    fdOKButton
    fdOpenButton
    fdReplaceButton
    fdClearButton
    fdHelpButton
    fdNoLoadDir
  )],

  FA_ => [qw(
    FA_NORMAL
    FA_RDONLY
    FA_HIDDEN
    FA_SYSTEM
    FA_LABEL
    FA_DIREC
    FA_ARCH
  )],

  _A_ => [qw(
    _A_NORMAL
    _A_RDONLY
    _A_HIDDEN
    _A_SYSTEM
    _A_VOLID
    _A_SUBDIR
    _A_ARCH
  )],

  DIR => [qw(
    WILDCARDS
    EXTENSION
    FILENAME
    DIRECTORY
    DRIVE
  )],

  MAX => [qw(
    MAXDRIVE
    MAXPATH
    MAXDIR
    MAXFILE
    MAXEXT
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

# TFileInfoPane palette layout

use constant cpInfoPane => "\x1E";

# TFileDialog options

use constant {
  fdOKButton      => 0x0001,    # Put an OK button in the dialog
  fdOpenButton    => 0x0002,    # Put an Open button in the dialog
  fdReplaceButton => 0x0004,    # Put a Replace button in the dialog
  fdClearButton   => 0x0008,    # Put a Clear button in the dialog
  fdHelpButton    => 0x0010,    # Put a Help button in the dialog
  fdNoLoadDir     => 0x0100,    # Do not load the current directory
                                # contents into the dialog at BUILD.
                                # This means you intend to change the
                                # wildCard by using setData or store
                                # the dialog on a stream.
};

# DOS-Attributes for File Dialogs

use constant {
  FA_NORMAL => 0x00,    # Normal file, no attributes
  FA_RDONLY => 0x01,    # Read only attribute
  FA_HIDDEN => 0x02,    # Hidden file
  FA_SYSTEM => 0x04,    # System file
  FA_LABEL  => 0x08,    # Volume label
  FA_DIREC  => 0x10,    # Directory
  FA_ARCH   => 0x20,    # Archive
};

# MSC names for file attributes

use constant {
  _A_NORMAL => 0x00,    # Normal file, no attributes
  _A_RDONLY => 0x01,    # Read only attribute
  _A_HIDDEN => 0x02,    # Hidden file
  _A_SYSTEM => 0x04,    # System file
  _A_VOLID  => 0x08,    # Volume label
  _A_SUBDIR => 0x10,    # Directory
  _A_ARCH   => 0x20,    # Archive
};

# Borland-RTL-Attributes for File Dialogs

use constant {
  WILDCARDS => 0x01,
  EXTENSION => 0x02,
  FILENAME  => 0x04,
  DIRECTORY => 0x08,
  DRIVE     => 0x10,
};

use constant {
  MAXDRIVE  => 3,
  MAXPATH   => 260,
  MAXDIR    => 256,
  MAXFILE   => 256,
  MAXEXT    => 256,
};

1
