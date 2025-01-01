=pod

=head1 DESCRIPTION

defines various utility functions used throughout Turbo Vision

=cut

package TV::Memory::Util;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(
  lowMemory
);

sub lowMemory() {    # $bool ()
  !!0;
}

1
