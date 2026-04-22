package TV::Memory::Util;
# ABSTRACT: defines various utility functions used throughout Turbo Vision

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use TV::toolkit::boolean;

use Exporter 'import';

our @EXPORT_OK = qw(
  lowMemory
);

sub lowMemory () {    # $bool ()
  false;
}

1
