package TV::StdDlg::FileCollection;
# ABSTRACT: Sorted collection of file and directory search entries

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TFileCollection
  new_TFileCollection
);

use Class::Struct;
use TV::toolkit;
use TV::toolkit::Types qw(
  is_Object
  :types
);

use TV::Objects::SortedCollection;
use TV::StdDlg::Const qw( FA_DIREC );

struct TSearchRec => [
  attr => '$',
  time => '$',
  size => '$',
  name => '$',
];

sub TFileCollection() { __PACKAGE__ }
sub name() { 'TFileCollection' };
sub new_TFileCollection { __PACKAGE__->from(@_) }

extends TSortedCollection;

# predeclare private methods
my (
  $getName,
  $attr,
);

sub BUILDARGS {    # \%args (|%args)
  state $sig = signature(
    method => 1,
    named => [
      limit => Int, { alias => 'aLimit' },
      delta => Int, { alias => 'aDelta' },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub from {    # $obj ($aLimit, $aDelta)
  state $sig = signature(
    method => 1,
    pos => [Int, Int],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( limit => $args[0], delta => $args[1] );
}

$getName = sub {    # $name ($k)
  assert ( @_ == 1 );
  assert ( is_Object $_[0] );
  goto &TSearchRec::name;
};

$attr = sub {    # $attr ($k)
  assert ( @_ == 1 );
  assert ( is_Object $_[0] );
  goto &TSearchRec::attr;
};

sub compare {    # $cmp ($key1, $key2)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike, ArrayLike],
  );
  my ( $self, $key1, $key2 ) = $sig->( @_ );
  return 0
    if ( $key1->$getName() cmp $key2->$getName() ) == 0;

  return 1
    if ( $key1->$getName() cmp ".." ) == 0;
  return -1
    if ( $key2->$getName() cmp ".." ) == 0;

  return 1
    if ( $key1->$attr() & FA_DIREC ) != 0
    && ( $key2->$attr() & FA_DIREC ) == 0;
  return -1
    if ( $key2->$attr() & FA_DIREC ) != 0
    && ( $key1->$attr() & FA_DIREC ) == 0;

  return $key1->$getName() cmp $key2->$getName();
} #/ sub compare

1
