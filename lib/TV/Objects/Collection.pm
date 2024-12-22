package TV::Objects::Collection;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TCollection
);

use TV::Objects::NSCollection;
use TV::toolkit;

sub TCollection() { __PACKAGE__ }
sub name() { 'TCollection' };

extends TNSCollection;

1
