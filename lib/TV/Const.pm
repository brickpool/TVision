package TV::Const;
# ABSTRACT: Miscellaneous system-wide configuration parameters.

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT_OK = qw(
  INT_MAX
  UINT_MAX

  EOS

  maxFindStrLen
  maxReplaceStrLen
);

use constant {
  INT_MAX  => ~0 >> 1,
  UINT_MAX => ~0,
};

use constant {
  EOS => q{},
};

use constant {
  maxFindStrLen     => 80,
  maxReplaceStrLen  => 80,
};

1
