=pod

=head1 NAME

TurboVision::Drivers::Utility - Utility Routines

=cut

package TurboVision::Drivers::Utility;

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

use Data::Alias qw( alias );
use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';

use TurboVision::Drivers::Const qw( :private );

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 EXPORTS

Nothing per default, but can export the following per request:

  :all
  
    :kbd
      ctrl_to_arrow
      get_alt_char
      get_alt_code
      get_ctrl_char
      get_ctrl_code

    :str
      format_str
      print_str
      
    :move
      c_str_len
      move_buf
      move_c_str
      move_char
      move_str

=cut

use Exporter qw(import);

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (

  kbd => [qw(
    ctrl_to_arrow
    get_alt_char
    get_alt_code
    get_ctrl_char
    get_ctrl_code
  )],

  str => [qw(
    format_str
    print_str
  )],

  move => [qw(
    c_str_len
    move_buf
    move_c_str
    move_char
    move_str
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

=head2 Subroutines

=head3 Keyboard support routines

=over

=item I<ctrl_to_arrow>

  func ctrl_to_arrow(Int|Str $key_code) : Int

This esoteric function converts certain control-key combinations to standard
I<kbXXXX> constant values.

The original WordStar word processor used a standard set of Ctrl-letter
combinations as equivalents to IBM cursor movement keys and set a standard
interpretation of these keys when used in word processing.

To assist in providing WordStar compatibility, I<ctrl_to_arrow> can be used to
convert I<< $event->key_code >> values to their corresponding I<kbXXXX> values.

The following chart shows the mapping from control keys to I<kbXXXX> values.

  Control key   Lo(Keycode)   Maps to
  Ctrl-A        0x01          KB_HOME
  Ctrl-D        0x04          KB_RIGHT
  Ctrl-E        0x05          KB_UP
  Ctrl-F        0x06          KB_END
  Ctrl-G        0x07          KB_DEL
  Ctrl-S        0x13          KB_LEFT
  Ctrl-V        0x16          KB_INS
  Ctrl-X        0x18          KB_DOWN

=cut

  func ctrl_to_arrow(Int|Str $key_code) {
    return _WORD_STAR_CODES->( $key_code ) // $key_code;
  }

=item I<get_alt_char>

  func get_alt_char(Int $key_code) : Str

When I<$key_code> specifies an I<Alt+Ch> character combination, where I<Ch> is a
letter from 'A' to 'Z', I<get_alt_char> extracts and returns the I<Ch>
character value.

For example,
  
  print get_alt_char( KB_ALT_A );

prints the single letter I<A>.

The subroutine L</get_alt_code> maps characters back to I<Alt+Ch> combinations.

=cut

  func get_alt_char(Int $key_code) {
    return chr(0xf0)                                    # special case Alt-Space
        if $key_code == 0x0200;

    return "\0"                                         # no extended key
        if $key_code & 0xff;

    my $hi = $key_code >> 8 & 0xff;

    if ( $hi <= 0x83 ) {                                # highest value in list
      for my $i (0..127) {                              # search for match
        return chr($i)                                  # return character
            if $hi == _ALT_CODES->( $i );
      }
    }

    return "\0";
  }

=item I<get_alt_code>

  func get_alt_code(Str $ch) : Int

Maps a single character 'A' to 'Z' to the Keycode equivalent value for pressing
I<Alt+Ch>.

For example,

  get_alt_code(Str $ch);

returns C<0x1e00>, which is the value of KB_ALT_A.

The subroutine I<get_alt_code> is the inverse function to L</get_alt_char>.

=cut

  func get_alt_code(Str $ch) {
    return 0x0200
        if ord($ch) == 0xf0;                            # special case Alt-Space
      
    $ch = ord( uc($ch) );
    
    return _ALT_CODES->($ch) << 8
        if $ch >= 0 && $ch <= 127;

    return 0;
  }

=item I<get_ctrl_char>

  func get_ctrl_char(Int $key_code) : Str

Returns the ASCII character for the I<Ctrl+Key> scancode that was given.

=cut

  func get_ctrl_char(Int $key_code) {
    my $lo = $key_code & 0xff;

    return chr($lo + 0x40)                              # return char a-z
        if $lo >= 1 && $lo <= 26;                       # between 1-26

    return "\0";
  }

=item I<get_ctrl_code>

  func get_ctrl_code(Str $ch) : Int

Returns the scancode corresponding to I<Ctrl+Ch> key that is given.

=cut

  func get_ctrl_code(Str $ch) {
    return get_alt_code($ch) | ord($ch) - 0x40;         # Ctrl+key code
  }

=back

=head3 String routines

=over

=item I<format_str>

  func format_str(Str $result, Str $format, @params)

I<format_str> takes a string I<$format> and a list of parameters in I<@params>
and produces a formatted string that is returned in Result.

I<format_str> is typically used to insert parameter values into predefined
strings, such as those used for error messages, or general program strings
stored in a resource file.

The Format string contains both text and imbedded formatting information, as in
this example:

  'File %s is %d bytes in size.'

The formatting characters I<%s> and I<%d> indicate that a string and a decimal
value, respectively, should be substituted in these locations.

The values for the substitutions are specified in the Params parameter as shown
in the example code, below.

I<$format> specifiers have the form I<< % [-] [nnn] X >>, where the brackets
indicate optional items and I<X> is a format character.

  Table of Format Specifiers
  %   Marks the beginning of a format specifier
  
  -   Indicates the items should be left justified (default is right justified)
  
  nnn Specifies the width of the result, where nnn is in the range from 0 to
      255.
      
      0 is equivalent to not specifying a width.
      
      If nnn is less than the width needed to display a particular item, the
      item is truncated to fit within the width value.
      
      For example, %3s allocates 3 character spaces. If the string parameter
      contains 'Turbo', then only the last 3 characters 'rbo' will be inserted
      into the result.
      
      If you use %-3s, then only the first 3 characters will be inserted, giving
      'Tur'.
  
  s   Format character indicating the parameter is a string pointer.
  
  d   Format character indicating the parameter is a Longint and is to be
      displayed in decimal.
  
  c   Format character specifying the low byte of the parameter is a character
      value.
  
  x   Format character specifying the parameter is a Longint to be displayed in
      hexadecimal.
  
  #   Resets the parameter index to the optional nnn value.

The I<@params> parameter variable contains the data corresponding to each item
specified in the I<$format> string. There are two ways to pass the variable
I<@params>: B<1)> Pass the individual parameters comma separated, B<2)> Or use
an array.

B<Note>: This utility routine is for compatiblity only; please use the Perl
built in function I<sprintf>.

=cut

  func format_str($, Str $format, @params) {
    alias my $result = $_[-2 -scalar(@params)];
    assert ( is_Str $result );

    # convert '% [-] 000 X' to '% [-] X'
    $format =~ s/(%\-?)0{1,3}([sdcx])/$1$2/;

    # convert '% [-] [nnn] #' to '% [-] [nnn] $'
    $format =~ s/(%\-?\d{1,3})#/$1\$/;

    # set maximum width incl. left-justify for '% [-] nnn s'
    $format = do {
      my $fmt = '';
      my $i = 0;
      foreach ( split /(%\-?\d{0,3}s)/, $format ) {
        # Check format identifier and existing parameters
        if ( /%(\-?\d{1,3})s/ && defined $params[$i] ) {
          my $flags = $1;
          my $width = abs $1;
          $params[$i] = $flags+0 < 0
            ? substr($params[$i], 0, $width)
            : substr($params[$i], -$width)
            ;
          if ( $width > length $params[$i] ) {
            if ( $flags =~ /^[1-9]/ ) {
              $_ = '%s';
            }
            elsif ( $flags =~ /\-0/ ) {
              while ( $width > length $params[$i] ) {
                $params[$i] .= '0';
              }
              $_ = '%s';
            }
          }
        }
        $fmt .= $_;
        $i++ if /%\-?\d{0,3}s/;
      }
      $fmt;
    };

    $result = sprintf($format, @params);
    return;
  }

=item I<print_str>

  func print_str(Str $s)

Writes the string I<$s> to STDOUT.

B<Note>: This utility routine is for compatiblity only; please use the Perl
built in function I<print>.

=cut

  func print_str(Str $s) {
    print $s;
    return;
  }

=back

=head3 Buffer move routines

=over

=item I<c_str_len>

  func c_str_len(Str $s) : Int

Returns the length of control strings, which are any strings containing
short-cut characters surrounded by tilde '~' characters, minus the number of
tilde characters. For example,

  c_str_len( '~F~ile' );

has a length of 4.

=cut

  func c_str_len(Str $s) {
    $s =~ s/~//g;
    return length $s
  }

=item I<move_buf>

  func move_buf(ArrayRef $dest, ArrayRef $source, Int $attr, Int $count)

I<move_buf> is typically used for copying text and video attribute to a
I<TDrawBuffer>-type array.

Such an array holds character bytes in the I<"low byte(s)"> of each element and
attribute values in the I<"high byte(s)">. 

I<move_buf> copies I<$count> elements from I<$source> into the I<"low byte(s)">
of the I<$dest> destination parameter, setting each I<"high byte(s)"> to the
I<$attr> value (or leaving the attribute as is if I<$attr> equals zero).

B<See>: L</move_char>, I<TDrawBuffer>, I<< TView->write_buf >> and
I<< TView->write_line >>.

=cut

  func move_buf(ArrayRef $dest, ArrayRef $source, Int $attr, Int $count) {
    for (my $i = 0; $i < $count; $i++) {
      alias my $p = $dest->[$i];                      # Pointer to element
      $p->{hi} = $attr if $attr != 0;                 # Copy attribute
      $p->{lo} = $source->[$i]->{lo};                 # Copy source data
    }
    return;
  }

=item I<move_c_str>

  func move_c_str(ArrayRef $dest, Str $str, @attrs)

I<move_c_str> copies a string to a I<TDrawBuffer> array such that the text is
alternately one of two different colors.

I<move_c_str> copies the I<$str> string parameter to the I<$dest> (a
I<TDrawBuffer> array) and sets each character's attributes using either the
first or second element of the I<@attrs> array.

Initially, I<move_c_str> uses the second element of I<@attrs>, but upon
encountering a "~" tilde character, I<move_c_str> switches to the first element
of I<@attrs>.

Each tilde in the string causes I<move_c_str> to toggle to the other I<@attrs>
attribute element.

I<move_c_str> is used by Turbo Vision for setting up pulldown menu strings where
the hot keys are set off in a different color from the rest of the text.

For example, 

  new_sub_menu('~R~un', HC_NO_CONTEXT, new_menu( ...

You use I<move_c_str> like this:

  my $a_buffer = [];
  ...
  move_c_str( $a_buffer, 'This ~is~ some text.', 0x07, 0x70 );
  $self->write_line( 10, 10, 18, 1, $a_buffer );

This sets the word 'is' to the attribute C<0x07> and the rest of the text to
C<0x70>.

B<See>: I<TDrawBuffer>, L</move_char>, L</move_buf>, L</move_str>,
I<< TView->write_buf >> and I<< TView->write_line >>.

=cut

  func move_c_str(ArrayRef $dest, Str $str, @attrs) {
    assert ( @attrs == 2 );
    assert ( is_Int $attrs[0] );
    assert ( is_Int $attrs[1] );
  
    my $j = 0;                                        # Start position
    for ( my $i = 0; $i < length($str); $i++ ) {      # For each character
      if ( substr($str, $i, 1) ne '~' ) {             # Not tilde character
        alias my $p = $dest->[$j];                    # Pointer to element
        if ( $attrs[1] != 0 ) {
          $p->{hi} = $attrs[1];                       # Copy attribute
          $p->{lo} = substr($str, $i, 1);             # Copy string char
          $j++;                                       # Next position
        }
      }
      else {
        @attrs = ( $attrs[1], $attrs[0] );            # Complete exchange
      }
    }
    return;
  }


=item I<move_char>

  func move_char(ArrayRef $dest, Str $c, Int $attr, Int $count)

Similar to L</move_buf>, except that this copies the single character I<$c>,
I<$count> number of times, into each I<"low byte(s)"> of the I<$dest> parameter
(which should be a I<TDrawBuffer> type), and if I<$attr> is non-zero, copies
I<$attr> to each I<"high byte(s)"> position in the array of elements.

B<See>: L</move_buf>, I<TDrawBuffer>, I<< TView->write_buf >> and
I<< TView->write_line >>.

=cut

  func move_char(ArrayRef $dest, Str $c, Int $attr, Int $count) {
    assert ( length $c == 1 );

    for (my $i = 0; $i < $count; $i++) {
      alias my $p = $dest->[$i];                      # Pointer to element
      $p->{hi} = $attr if $attr != 0;                 # Copy attribute
      $p->{lo} = $c;                                  # Copy character 
    }
    return;
  }

=item I<move_str>

  func move_str(ArrayRef $dest, Str $str, Int $attr)

I<move_str> copies the I<$str> string parameter to the I<$dest> (a
I<TDrawBuffer> array) and sets each character's attributes to the video
attribute contained in I<$attr>.

B<See>: I<TDrawBuffer>, L</move_char>, L</move_buf>, L</move_c_str>,
I<< TView->write_buf >> and I<< TView->write_line >>.

=cut

  func move_str(ArrayRef $dest, Str $str, Int $attr) {
    for (my $i = 0; $i < length($str); $i++) {
      alias my $p = $dest->[$i];                      # Pointer to element
      $p->{hi} = $attr if $attr != 0;                 # Copy attribute
      $p->{lo} = substr($str, $i, 1);                 # Copy string char
    }
    return;
  }

=back

=cut

1;

__END__

=head1 COPYRIGHT AND LICENCE

 This file is part of the port of the Free Vision library.
 Copyright (c) 1996-2000 by Leon de Boer.

 Interface Copyright (c) 1992 Borland International

 The library files are licensed under modified LGPL.

 The creation of subclasses of this LGPL-licensed class is considered to be
 using an interface of a library, in analogy to a function call of a library.
 It is not considered a modification of the original class. Therefore,
 subclasses created in this way are not subject to the obligations that an LGPL
 imposes on licensees.

 POD sections by Ed Mitchell are licensed under modified CC BY-NC-ND.

=head1 AUTHORS

=over

=item *

1996-2000 by Leon de Boer E<lt>ldeboer@attglobal.netE<gt>

=item *

1992 by Ed Mitchell (Turbo Pascal Reference electronic freeware book)

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

L<drivers.pas|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/fv/src/drivers.pas>
