=pod

=head1 NAME

TurboVision::Const - Private constants used by Turbo Vision

=head1 SYNOPSIS

  use TurboVision::Const qw(
    _EMPTY_STRING
    :bool
  );
  ...

=cut

package TurboVision::Const;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

# version '...'
our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;

# authority '...'
our $AUTHORITY = 'github:fpc';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use Config;
use English qw( -no_match_vars );
use Exporter qw( import );

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 EXPORTS

Nothing per default, but can export the following per request:

  :all
    _EMPTY_STRING
    
    :bool
      _FALSE
      _TRUE

    :limits
      _INT32_MIN
      _INT32_MAX
      _SIMPLE_STR_MAX
      _UINT8_MAX
      _UINT16_MAX

    :platform
      _TV_UNIX
      _WIN32

    :sizedef
      _SIZE_OF_INT32
      _SIZE_OF_UINT8
      _SIZE_OF_UINT16

    :typedef
      _INT32_T
      _SIMPLE_STR_T
      _STR_T
      _UINT8_T
      _UINT16_T
      _UINT32_T

=cut

our @EXPORT_OK = qw(
  _EMPTY_STRING
);

our %EXPORT_TAGS = (

  bool => [qw(
    _FALSE
    _TRUE
  )],

  limits => [qw(
    _INT32_MIN
    _INT32_MAX
    _SIMPLE_STR_MAX
    _UINT8_MAX
    _UINT16_MAX
  )],

  platform => [qw(
    _TV_UNIX
    _WIN32
  )],

  sizedef => [qw(
    _SIZE_OF_INT32
    _SIZE_OF_UINT8
    _SIZE_OF_UINT16
  )],

  typedef => [qw(
    _INT32_T
    _SIMPLE_STR_T
    _STR_T
    _UINT8_T
    _UINT16_T
    _UINT32_T
  )],

);

# add all the other %EXPORT_TAGS ":class" tags to the ":all" class and
# @EXPORT_OK, deleting duplicates
{
  my %seen;
  push
    @EXPORT_OK,
      grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}}
        foreach keys %EXPORT_TAGS;
  push
    @{$EXPORT_TAGS{all}},
      @EXPORT_OK;
}

# ------------------------------------------------------------------------
# Constants --------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 CONSTANTS

=head2 Unclassified constants

=over

=item private const C<< Int _EMPTY_STRING >>

An empty string C<q{}>.

=cut

  use constant _EMPTY_STRING  => q{};

=back

=cut

=head2 Boolean constants (I<:bool>)

=over

=item private const C<< Bool _FALSE >>

False constant.

=cut

  use constant _FALSE => !! '';

=item private const C<< Bool _TRUE >>

True constant.

=cut

  use constant _TRUE  => !! 1;

=back

=cut

=head2 Limit value constants (I<:limits>)

=over

=item private const C<< Str _INT32_MAX >>

Maximum value for a variable of the type signed long (32-bit).

=cut

  use constant _INT32_MAX       => 2147483647;

=item private const C<< Str _SIMPLE_STR_T >>

Template for pack/unpack of a string of the Moose type I<SimpleStr> value as
"length/string".

=cut

  use constant _INT32_MIN       => -2147483647 - 1;

=item private const C<< Int _SIMPLE_STR_MAX >>

This variable is the size of a string of type Moose I<SimpleStr> in bytes.

=cut

  use constant _SIMPLE_STR_MAX  => 255;

=item private const C<< Int _UINT8_MAX >>

Maximum value for a variable of the type unsigned char (octet).

=cut

  use constant _UINT8_MAX       => 255;   # 0xff

=item private const C<< Int _UINT16_MAX >>

Maximum value for a variable of the type unsigned short (16-bit).

=cut

  use constant _UINT16_MAX      => 65535; # 0xffff

=back

=cut

=head2 Platform dependent constants (I<:platform>)

=over

=item private const C<< Bool _WIN32 >>

True if C<$^O eq 'MSWin32'>.

=cut

  use constant _WIN32   => $OSNAME eq 'MSWin32';

=item private const C<< Bool _TV_UNIX >>

True if C<$^O ne 'MSWin32'>.

=cut

  use constant _TV_UNIX => !_WIN32;

=back

=cut

=head2 Constants to define the size (I<:sizedef>)

=over

=item private const C<< Int _SIZE_OF_INT32 >>

This variable is the size of an Perl's I32 in bytes.

=cut

  use constant _SIZE_OF_INT32   => $Config{i32size};

=item private const C<< Int _SIZE_OF_UINT8 >>

This variable is the size of an Perl's U8 in bytes.

=cut

  use constant _SIZE_OF_UINT8   => $Config{u8size};

=item private const C<< Int _SIZE_OF_UINT16 >>

This variable is the size of an Perl's U16 in bytes.

=cut

  use constant _SIZE_OF_UINT16  => $Config{u16size};

=back

=cut

=head2 Constants to define a type (I<:typedef>)

=over

=item private const C<< Str _INT32_T >>

Template for pack/unpack of an signed long (32-bit) value in "VAX"
(little-endian) order.

=cut

  use constant _INT32_T       => 'V!';

=item private const C<< Str _SIMPLE_STR_T >>

Template for pack/unpack of a string of the Moose type I<SimpleStr> value as
"length/string".

=cut

  use constant _SIMPLE_STR_T  => 'C/A*';

=item private const C<< Str _STR_T >>

Template for pack/unpack of a string of the Moose type I<Str> value as
"length/string".

=cut

  use constant _STR_T         => 'v/A*';

=item private const C<< Str _UINT8_T >>

Template for pack/unpack of an unsigned char (octet) value.

=cut

  use constant _UINT8_T       => 'C';

=item private const C<< Str _UINT16_T >>

Template for pack/unpack of an unsigned short (16-bit) value in "VAX"
(little-endian) order.

=cut

  use constant _UINT16_T      => 'v';

=item private const C<< Str _UINT32_T >>

Template for pack/unpack of an unsigned short (32-bit) value in "VAX"
(little-endian) order.

=cut

  use constant _UINT32_T      => 'V';

=back

=cut

1;

__END__

=head1 COPYRIGHT AND LICENCE

 This file is part of the port of the Free Pascal run time library.
 Copyright (c) 1999-2000 by the Free Pascal development team.

 Interface Copyright (c) 1992 Borland International

 The run-time files are licensed under modified LGPL.

 The creation of subclasses of this LGPL-licensed class is considered to be
 using an interface of a library, in analogy to a function call of a library.
 It is not considered a modification of the original class. Therefore,
 subclasses created in this way are not subject to the obligations that an LGPL
 imposes on licensees.

=head1 AUTHORS
 
=over

=item *

2022 by J. Schneider L<https://github.com/brickpool/>

=back

=head1 DISCLAIMER OF WARRANTIES
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.

=head1 SEE ALSO

I<Exporter>
