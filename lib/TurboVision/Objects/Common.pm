=pod

=head1 NAME

TurboVision::Objects::Common - Routines and tools used by I<Objects>

=head1 SYNOPSIS

  use 5.014;
  use TurboVision::Objects::Common qw( :all );
  
  sub init {
    my ($class, @args) = @_;
    return fail() if @args != 1;
    ...
  }
  ...
  sub get_item {
    abstract();
    return;
  }
  ...
  say long_div(5, 2);
  say long_mul(5, 2);
  ...
  say word_rec($w)->lo;
  say long_rec($l)->hi;
  say ptr_rec($p)->ofs;
  ...

=cut

package TurboVision::Objects::Common;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

use Function::Parameters {
  func => {
    defaults    => 'function_strict',
    name        => 'required',
  },
};

use MooseX::Types::Moose qw( :all );

# version '...'
our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;

# authority '...'
our $AUTHORITY = 'github:fpc';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use Carp qw( confess );
use Data::Alias qw( alias );
use English qw( -no_match_vars );
use Scalar::Util qw( refaddr weaken isweak );

use TurboVision::Const qw(
  :limits
  :sizedef
  :typedef
);
use TurboVision::Objects::Types qw(
  TCollection
  TStreamRec
  TStringCollection
);

use Contextual::Return;   # must be used after 'TurboVision::Objects::Types'

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 EXPORTS

Nothing per default, but can export the following per request:

  :all
  
    :tools
      byte
      integer
      longint
      long_div
      long_mul
      long_rec
      ptr_rec
      word
      word_rec
    
    :subs
      abstract
      dispose_str
      fail
      new_str
      register_objects

=cut

use Exporter qw(import);

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (

  tools => [qw(
    byte
    integer
    longint
    long_div
    long_mul
    long_rec
    ptr_rec
    word
    word_rec
  )],

  subs => [qw(
    abstract
    dispose_str
    fail
    new_str
    register_objects
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
# Subroutines ------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

Routines and tools that are used in all modules and, if applicable, in the
program and have been assigned to the I<Objects> module.

=head2 Tools

=over

=item I<byte>

  func byte() : Object
  func byte(Str|Int $value) : Object

The utility I<byte> helps to convert an unsigned char (octet) value into a
number to the base 256 (packed string).

A I<byte> data type support only positive I<Int> values in a range of:
C<0..255>.

Usage:

  $ = byte()->type;       # uint8 template for the conversion
  $ = byte()->size;       # Size of a uint8 value in bytes

  $ = byte($int)->cast;   # Conversion of an integer to a uint8 value
  $ = byte($int)->pack;   # Conversion from uint8 to a number in base 256
  $ = byte($str)->unpack; # Conversion of a number with base 256 into uint16

=cut

  func byte(Int|Str|Undef $value=) {
    if ( !defined($value) ) {
      return (
        METHOD {
          '^size$' => sub { _SIZE_OF_UINT8 },
          '^type$' => sub { _UINT8_T       },
        }
      );
    }
    else {
      return (
        METHOD {
          '^cast$'   => sub {
            return FAIL if not is_Int $value;
            return $value & 0xff;
          },
          '^pack$'   => sub {
            return FAIL if not is_Int $value;
            return pack(_UINT8_T, $value);
          },
          '^unpack$' => sub {
            return FAIL if not is_Str $value;
            return unpack(_UINT8_T, $value);
          },
        }
      );
    }
    return FAIL;
  }

=item I<integer>

  func integer() : Object
  func integer(Str|Int $value) : Object

The utility I<integer> helps to convert an signed long (16-bit) value into a
number to the base 256 (packed string).

A I<integer> data type support only positive I<Int> values in a range of:
C<-32768..32767>.

Usage:

  $ = integer()->type;       # int16 template for the conversion
  $ = integer()->size;       # Size of a int16 value in bytes

  $ = integer($int)->cast;   # Conversion of an integer to a int16 value
  $ = integer($int)->pack;   # Conversion from int16 to a number in base 256
  $ = integer($str)->unpack; # Conversion of a number with base 256 into int32

=cut

  func integer(Int|Str|Undef $value=) {
    if ( !defined($value) ) {
      return (
        METHOD {
          '^size$' => sub { _SIZE_OF_INT16 },
          '^type$' => sub { _INT16_T       },
        }
      );
    }
    else {
      return (
        METHOD {
          '^cast$'   => sub {
            return FAIL if not is_Int $value;
            return unpack(_INT16_T, pack(_INT16_T, $value));
          },
          '^pack$'   => sub {
            return FAIL if not is_Int $value;
            return pack(_INT16_T, $value);
          },
          '^unpack$' => sub {
            return FAIL if not is_Str $value;
            return unpack(_INT16_T, $value);
          },
        }
      );
    }
    return FAIL;
  }

=item I<longint>

  func longint() : Object
  func longint(Str|Int $value) : Object

The utility I<longint> helps to convert an signed long (32-bit) value into a
number to the base 256 (packed string).

A I<longint> data type support only positive I<Int> values in a range of:
C<-2147483648..2147483647>.

Usage:

  $ = longint()->type;       # int32 template for the conversion
  $ = longint()->size;       # Size of a int32 value in bytes

  $ = longint($int)->cast;   # Conversion of an integer to a int32 value
  $ = longint($int)->pack;   # Conversion from int32 to a number in base 256
  $ = longint($str)->unpack; # Conversion of a number with base 256 into int32

=cut

  func longint(Int|Str|Undef $value=) {
    if ( !defined($value) ) {
      return (
        METHOD {
          '^size$' => sub { _SIZE_OF_INT32 },
          '^type$' => sub { _INT32_T       },
        }
      );
    }
    else {
      return (
        METHOD {
          '^cast$'   => sub {
            return FAIL if not is_Int $value;
            return unpack(_INT32_T, pack(_INT32_T, $value));
          },
          '^pack$'   => sub {
            return FAIL if not is_Int $value;
            return pack(_INT32_T, $value);
          },
          '^unpack$' => sub {
            return FAIL if not is_Str $value;
            return unpack(_INT32_T, $value);
          },
        }
      );
    }
    return FAIL;
  }

=item I<long_div>

  func long_div(Int $x, Int $y) : Int

A division routine, returning the integer value C<int( $x/$y )>.

B<Note>: This utility routine is for compatiblity only.

=cut

  func long_div(Int $x, Int $y) {
    return int( $x / $y );
  }

=item I<long_mul>

  func long_mul(Int $x, Int $y) : Int

A multiplication routine, returning the integer value C<$x*$y>.

B<Note>: This utility routine is for compatiblity only.

=cut

  func long_mul(Int $x, Int $y) {
    return $x * $y;
  }

=item I<long_rec>

  func long_rec(Int $l) : Object|Value

A utility routine allowing access to the I<< long_rec($l)->lo >> and
I<< long_rec($l)->hi >> words of I<$l>. In a scalar context the utility routine
returns C<$l & 0xffffffff>.

B<Note>: This utility routine is for compatiblity only. Please use
C<$hi = $int & 0xfffff0000> to get the hi-word or C<$lo = $int & 0x0000fffff> to
get lo-word of an integer value.

=cut

  func long_rec(Int $l) {
    return (
      METHOD {
        '^hi$' => sub { ($l & 0xffff_0000) >> 16 },
        '^lo$' => sub { ($l & 0x0000_ffff)       },
      }
      SCALAR { $l & 0xffff_ffff }
    );
  }

=item I<ptr_rec>

  func ptr_rec(Ref $p) : Object|Value

A utility routine that returns the memory address of a referenced value as
I<< ptr_rec($p)->seg >> and I<< ptr_rec($p)->ofs >>. In a scalar context the
utility routine returns C<refaddr($p)>.

B<Note>: Modern systems are not segmented and the addresses are always linear.
This utility routine is only for compatiblity. Please use Perl's routine
I<refaddr> instead to get the internal memory address of a referenced value.

See: I<refaddr> from L<Scalar::Util>

=cut

  func ptr_rec(Ref $p) {
    my $addr = refaddr($p);
    return (
      METHOD {
        '^seg$'   => sub { ($addr & ~0xffff) >> 4 },
        '^ofs$'   => sub { ($addr &  0xffff)      },
        '^addr$'  => sub { ($addr +  0     )      },
      }
      SCALAR { $addr }
    );
  }

=item I<word>

  func word() : Object
  func word(Str|Int $value) : Object

The utility I<word> helps to convert an unsigned short (16-bit) value into a
number to the base 256 (packed string).

A I<word> data type support only positive I<Int> values in a range of:
C<0..65535>.

Usage:

  $ = word()->type;       # uint16 template for the conversion
  $ = word()->size;       # Size of a uint16 value in bytes

  $ = word($int)->cast;   # Conversion of an integer to a uint16 value
  $ = word($int)->pack;   # Conversion from uint16 to a number in base 256
  $ = word($str)->unpack; # Conversion of a number with base 256 into uint16

=cut

  func word(Int|Str|Undef $value=) {
    if ( !defined($value) ) {
      return (
        METHOD {
          '^size$' => sub { _SIZE_OF_UINT16 },
          '^type$' => sub { _UINT16_T       },
        }
      );
    }
    else {
      return (
        METHOD {
          '^cast$'   => sub {
            return FAIL if not is_Int $value;
            return $value & 0xffff;
          },
          '^pack$'   => sub {
            return FAIL if not is_Int $value;
            return pack(_UINT16_T, $value);
          },
          '^unpack$' => sub {
            return FAIL if not is_Str $value;
            return unpack(_UINT16_T, $value);
          },
        }
      );
    }
    return FAIL;
  }

=item L<word_rec>

  func word_rec(Int $w) : Object|Value

A utility routine allowing access to the I<< word_rec($w)->lo >> and
I<< word_rec($w)->hi >> bytes of I<$w>. In a scalar context the utility routine
returns C<$w & 0xffff>.

B<Note>: This utility routine is for compatiblity only. Please use
C<$hi = $int & 0xff00> to get the hi-byte or C<$lo = $int & 0x00ff> to get
lo-byte of an (unsigned) integer value.

=cut

  func word_rec(Int $w) {
    return (
      METHOD {
        '^hi$' => sub { ($w & 0xff00) >> 8 },
        '^lo$' => sub { ($w & 0x00ff)      },
      }
      SCALAR { $w & 0xffff }
    );
  }

=back

=cut

=head2 Routines

=over

=item I<abstract>

  func abstract()

Terminates program with a run-time error 211. When implementing an abstract
object type, call I<abstract> in those methods that must be overridden in
descendant types. This ensures that any attempt to use instances of the abstract
object type will fail.

See: I<confess> from L<Carp>

=cut

  func abstract() {
    $ERRNO = -211;                                        # Runtime error 211
    confess 'Call to abstract method';
    return;
  }

=item I<dispose_str>

  func dispose_str(ScalarRef[Str] $s)

Weaken the string reference I<$s>.

B<Note>: This utility routine is for compatiblity only.

See: I<weaken> from L<Scalar::Util>

=cut

  func dispose_str($) {
    alias my $s = $_[-1];
    return
        if !defined($s)
        || !is_ScalarRef($s)
        || !is_Str( ${$s} )
        ;
    if ( !isweak($s) ) {
      weaken($s);                                         # Release reference
    }
    return;
  }

=item I<fail>

  func fail() : Undef

I<fail> (which calls I<FAIL> from module L<Contextual::Return>) can be used in a
constructor for an object or class. It will exit the constructor immediately.

This means that calling I<fail> inside I<new> (also applies to I<init> and
I<load> in this library) raise an exception or returns false (C<undef>) when
used in a boolean context.

See: I<FAIL> from L<Contextual::Return>

=cut

  sub fail {
    $ERRNO = -210;
    goto &FAIL;
  }

=item I<new_str>

  func new_str(Str $s) : Ref|Undef

If I<$s> is empty, I<new_str> returns C<undef>. Otherwise, I<new_str> returns a
reference to a copy of string I<$s>.

B<Note>: This utility routine is for compatiblity only.

=cut

  func new_str(Str $s) {
    return undef                                        # Return undef
        if !length($s);
    return \$s;                                         # Return result
  }

=item I<register_objects>

  func register_objects()

Calls I<register_type> for each of the class types defined in the I<Objects>
module: I<TCollection>, I<TStringCollection>

=cut

  func register_objects() {
    require TurboVision::Objects::Collection;
    require TurboVision::Objects::StringCollection;

    TStreamRec->register_type(TCollection->RCollection);
    TStreamRec->register_type(TStringCollection->RStringCollection);
    
    return;
  }

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

1999-2000 by Florian Klaempfl E<lt>fnklaemp@cip.ft.uni-erlangen.deE<gt>

=item *

1999-2000 by Frank ZAGO E<lt>zago@ecoledoc.ipc.frE<gt>

=item *

1999-2000 by MH Spiegel

=item *

1996, 1999-2000 by Leon de Boer E<lt>ldeboer@ibm.netE<gt>

=back

=head1 DISCLAIMER OF WARRANTIES

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.

=head1 MAINTAINER

=over

=item *

2021-2023 by J. Schneider L<https://github.com/brickpool/>

=back

=head1 SEE ALSO

L<Carp>, L<Scalar::Util>, I<Objects>, L<Contextual::Return>, 
L<objects.pp|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/rtl-extra/src/inc/objects.pp>
