=pod

=head1 DESCRIPTION

defines various utility functions used throughout Turbo Vision

=cut

package TV::Drivers::Util;

use Exporter 'import';

our @EXPORT_OK = qw(
  getAltChar
  getAltCode
  getCtrlChar
  getCtrlCode
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw(
  looks_like_number
);

my @altCodes1 = unpack '(a)*', "QWERTYUIOP\0\0\0\0ASDFGHJKL\0\0\0\0\0ZXCVBNM";
my @altCodes2 = unpack '(a)*', "1234567890-=";

sub getAltChar {    # $char ($keyCode)
  assert ( @_ == 1 );
  my $keyCode = shift;
  assert ( looks_like_number $keyCode );
  if ( ( $keyCode & 0xff ) == 0 ) {
    my $tmp = ( $keyCode >> 8 );

    if ( $tmp == 2 ) {
      return "\xF0";    # special case to handle alt-Space
    }
    elsif ( $tmp >= 0x10 && tmp <= 0x32 ) {
      return $altCodes1[ $tmp - 0x10 ];    # alt-letter
    }
    elsif ( $tmp >= 0x78 && tmp <= 0x83 ) {
      return $altCodes2[ $tmp - 0x78 ];    # alt-number
    }

  } #/ if ( ( $keyCode & 0xff...))
  return "\0";
} #/ sub getAltChar

sub getAltCode {    # $keyCode ($c)
  assert ( @_ == 1 );
  my $c = shift;
  assert ( defined $c and !ref $c );
  return 0
    unless $c;

  $c = uc( $c );

  return 0x200
    if ord( $c ) == 0xF0;    # special case to handle alt-Space

  for my $i ( 0 .. $#altCodes1 ) {
    return ( $i + 0x10 ) << 8
      if $altCodes1[$i] eq $c;
  }

  for my $i ( 0 .. $#altCodes2 ) {
    return ( $i + 0x78 ) << 8
      if $altCodes2[$i] eq $c;
  }

  return 0;
} #/ sub getAltCode

sub getCtrlChar {    # $char ($keyCode)
  assert ( @_ == 1 );
  my $keyCode = shift;
  assert ( looks_like_number $keyCode );
  return ( $keyCode & 0xff ) != 0
      && ( $keyCode & 0xff ) <= ( ord( 'Z' ) - ord( 'A' ) + 1 )
        ? chr( ( $keyCode & 0xff ) + ord( 'A' ) - 1 )
        : "\0";
}

sub getCtrlCode {    # $keyCode ($ch)
  assert ( @_ == 1 );
  my $ch = shift;
  assert ( defined $ch and !ref $ch );
  return getAltCode( $ch ) | 
    (
      (
        ( $ch ge 'a' && $ch le 'z' )
        ? ( ord( $ch ) & ~0x20 )
        : ord( $ch )
      ) - ord( 'A' ) + 1
    );
} #/ sub getCtrlCode

1
