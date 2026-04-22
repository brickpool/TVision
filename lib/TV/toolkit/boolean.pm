package TV::toolkit::boolean;

use strict;
use warnings;

our $VERSION = '0.02';

use Exporter 'import';

our @EXPORT = qw(
  true
  false
);

sub true  () { !!1 }
sub false () { !!0 }

1
