package TV::Menus::Const;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (

  cpXXXX => [qw(
    cpMenuView
    cpStatusLine
  )],

  menuAction => [qw(
    doNothing
    doSelect
    doReturn
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

use constant cpMenuView => "\x02\x03\x04\x05\x06\x07";

use constant cpStatusLine => "\x02\x03\x04\x05\x06\x07";

# Constants for menuAction
use constant {
  doNothing => 0,
  doSelect  => 1,
  doReturn  => 2,
};

1
