=pod

=head1 DESCRIPTION

defines various utility functions used throughout Turbo Vision

=cut

package TV::Memory::Util;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT_OK = qw(
  lowMemory
);

sub lowMemory() {    # $bool ()
  !!0;
}

1
