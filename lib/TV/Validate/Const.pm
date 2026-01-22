package TV::Validate::Const;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (

  vsXXXX => [qw(
    vsOk
    vsSyntax
  )],

  voXXXX => [qw(
    voFill
    voTransfer
    voReserved
  )],

  vtXXXX => [qw(
    vtDataSize
    vtSetData
    vtGetData
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

# TValidator Status constants

use constant {
  vsOk     =>  0,
  vsSyntax =>  1,    # Error in the syntax of either a TPXPictureValidator
};                   # or a TDBPictureValidator

# Validator option flags

use constant {
  voFill     => 0x0001,
  voTransfer => 0x0002,
  voReserved => 0x00fc,
};

# TVTransfer constants

use constant {
  vtDataSize => 0,
  vtSetData  => 1,
  vtGetData  => 2,
};

1
