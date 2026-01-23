package TV::MsgBox::Const;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (

  mfXXXX => [qw(
    mfWarning
    mfError
    mfInformation
    mfConfirmation

    mfYesButton
    mfNoButton
    mfOKButton
    mfCancelButton

    mfYesNoCancel
    mfOKCancel
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

# Message box classes

use constant {
  mfWarning      => 0x0000,    # Display a Warning box
  mfError        => 0x0001,    # Display a Error box
  mfInformation  => 0x0002,    # Display an Information Box
  mfConfirmation => 0x0003,    # Display a Confirmation Box
};

# Message box button flags

use constant {
  mfYesButton    => 0x0100,    # Put a Yes button into the dialog
  mfNoButton     => 0x0200,    # Put a No button into the dialog
  mfOKButton     => 0x0400,    # Put an OK button into the dialog
  mfCancelButton => 0x0800,    # Put a Cancel button into the dialog
};

use constant mfYesNoCancel => mfYesButton | mfNoButton | mfCancelButton;
                               # Standard Yes, No, Cancel dialog
use constant mfOKCancel => mfOKButton | mfCancelButton;
                               # Standard OK, Cancel dialog
                               
1
