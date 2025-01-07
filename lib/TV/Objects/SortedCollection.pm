package TV::Objects::SortedCollection;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

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
