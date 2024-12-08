package TV::Objects::Collection;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TCollection
);

use TV::Objects::NSCollection;

sub TCollection() { __PACKAGE__ }
sub name() { 'TCollection' };

use base TNSCollection;

use slots::less;

1
