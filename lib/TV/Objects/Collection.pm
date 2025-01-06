package TV::Objects::Collection;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TCollection
  new_TCollection
);

use TV::Objects::NSCollection;
use TV::toolkit;

sub TCollection() { __PACKAGE__ }
sub name() { 'TCollection' };
sub new_TCollection { __PACKAGE__->from(@_) }

extends TNSCollection;

1
