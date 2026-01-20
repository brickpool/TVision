package TV::Dialogs::Const;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (

  bfXXXX => [qw(
    bfNormal
    bfDefault
    bfLeftJust
    bfBroadcast
    bfGrabFocus
  )],

  cmXXXX => [qw(
    cmRecordHistory
    cmGrabDefault
    cmReleaseDefault
  )],

  cpXXXX => [qw(
    cpGrayDialog
    cpBlueDialog
    cpCyanDialog
    cpDialog
    cpButton
  )],
  
  dpXXXX => [qw(
    dpBlueDialog
    dpCyanDialog
    dpGrayDialog
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

# Button flags

use constant {
  bfNormal    => 0x00,
  bfDefault   => 0x01,
  bfLeftJust  => 0x02,
  bfBroadcast => 0x04,
  bfGrabFocus => 0x08,
};

# Command constants

use constant {
  # History Command constants
  cmRecordHistory => 60,

  # TButton Command constants
  cmGrabDefault    => 61,
  cmReleaseDefault => 62,
};

# TDialog palette layout

use constant cpGrayDialog =>
  "\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2A\x2B\x2C\x2D\x2E\x2F".
  "\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x3A\x3B\x3C\x3D\x3E\x3F";

use constant cpBlueDialog =>
  "\x40\x41\x42\x43\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f".
  "\x50\x51\x52\x53\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f";

use constant cpCyanDialog =>
  "\x60\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f".
  "\x70\x71\x72\x73\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f";

use constant cpDialog => cpGrayDialog;

# TButton palette layout

use constant cpButton => "\x0A\x0B\x0C\x0D\x0E\x0E\x0E\x0F";

# TDialog palette entries

use constant {
  dpBlueDialog => 0,
  dpCyanDialog => 1,
  dpGrayDialog => 2,
};

1
