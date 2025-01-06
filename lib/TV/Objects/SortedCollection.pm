package TV::Objects::SortedCollection;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TSortedCollection
  new_TSortedCollection
);

use TV::Objects::NSSortedCollection;
use TV::toolkit;

sub TSortedCollection() { __PACKAGE__ }
sub name() { 'TSortedCollection' };
sub new_TSortedCollection { __PACKAGE__->from(@_) }

extends TNSSortedCollection;

sub compare {    # $cmp ($self, $key1, $key2)
  return 0;
}

1
