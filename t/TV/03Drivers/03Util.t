=pod

=head1 DESCRIPTION

These test cases cover the functions C<getAltCode>, C<getCtrlChar> and 
C<getCtrlCode>. 

=cut

use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
  use_ok 'TV::Drivers::Util', qw(
    getAltCode
    getCtrlChar
    getCtrlCode
  );
}

# Test getAltCode function
subtest 'getAltCode' => sub {
  is( getAltCode( 'A' ), 0x1e00, 'getAltCode returns correct value for A' );
  is( getAltCode( ' ' ), 0,
    'getAltCode returns correct value for alt-Space' );
  is( getAltCode( '1' ), 0x7800, 'getAltCode returns correct value for 1' );
  is( getAltCode( '' ),  0, 
    'getAltCode returns correct value for empty string' );
};

# Test getCtrlChar function
subtest 'getCtrlChar' => sub {
  is( getCtrlChar( 0x01 ), 'A',  'getCtrlChar returns correct value for 0x01' );
  is( getCtrlChar( 0x1A ), 'Z',  'getCtrlChar returns correct value for 0x1A' );
  is( getCtrlChar( 0x1B ), "\0", 'getCtrlChar returns correct value for 0x1B' );
};

# Test getCtrlCode function
subtest 'getCtrlCode' => sub {
  is( getCtrlCode( 'A' ), 0x1e01, 'getCtrlCode returns correct value for A' );
  is( getCtrlCode( 'a' ), 0x1e01, 'getCtrlCode returns correct value for a' );
};

done_testing;
