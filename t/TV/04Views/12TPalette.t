=pod

=head1 DECRIPTION

In these test cases, the I<TPalette> class is tested in various ways:

  1. Initializing an object with 'data' and 'size'.
  2. Retrieving data using the 'get_data' method and '@{}' operator.
  3. Copying an object using 'copy_from' argument.
  4. In these test cases, the 'assign' method is tested

=cut

use strict;
use warnings;

use Test::More tests => 10;

BEGIN {
  use_ok 'TV::Views::Palette';
}

my $data = sub {
  my $res = '';
  for my $i ( 1 .. ord( $_[0]->get_data(0) ) ) {
    $res .= $_[0]->get_data( $i );
  }
  return $res;
};

my $size = sub {
  return ord $_[0]->get_data(0);
};

# Test 1: Object initialization with data and size
my $palette = TPalette->new( data => 'abcd', size => 3 );
is( $palette->$data(), 'abc', 'Data(4) initialized correctly' );
is( $palette->$size(), 3,     'Size initialized correctly' );

$palette = TPalette->new( data => 'xy', size => 3 );
is( $palette->$data(), "xy\0", 'Data(2) initialized correctly' );
is( $palette->$size(), 3,      'Size initialized correctly' );

# Test 2: Data retrieval with get_data
is( $palette->get_data( 1 ), 'x',        'Data retrieved correctly' );
is( $palette->[2],           ord( 'y' ), '[] operator retrieved correctly' );

# Test 3: Copying an object
$palette = TPalette->new( data => 'abc', size => 3 );
my $palette_copy = TPalette->new( copy_from => $palette );
is( $palette_copy->$data(), 'abc', 'Data copied correctly' );

# Test 4: Assigning data from one object to another
my $palette_new = TPalette->new( data => '1234', size => 4 );
$palette_new->assign( $palette );
is( $palette_new->$data(), 'abc', 'Data assigned correctly' );
is( $palette_new->$size(), 3,     'Size initialized correctly' );

done_testing;
