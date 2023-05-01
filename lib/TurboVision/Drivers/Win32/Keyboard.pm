=pod

=head1 NAME

TurboVision::Drivers::Win32::Keyboard - Windows Keyboard Manager

=cut

package TurboVision::Drivers::Win32::Keyboard;

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
use PerlX::Assert;

use TurboVision::Const qw( :bool );
use TurboVision::Drivers::Const qw( :evXXXX );
use TurboVision::Drivers::Event;
use TurboVision::Drivers::Types qw(
  TEvent
  is_TEvent
);
use TurboVision::Drivers::Win32::EventQ qw( :private );

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
      get_key_event
      get_shift_state

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
    get_key_event
    get_shift_state
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

=over

=item public C<< Int ctrl_to_arrow(Int $key_code) >>

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

  func ctrl_to_arrow(Int $key_code) {
    return _WORD_STAR_CODES->($key_code) // $key_code;
  }

=item public C<< Str get_alt_char(Int $key_code) >>

When I<$key_code> specifies an I<Alt+Ch> character combination, where I<Ch> is a
letter from 'A' to 'Z', I<get_alt_char> extracts and returns the I<Ch>
character value.

For example,
  
  print get_alt_char( KB_ALT_A );

prints the single letter I<A>.

Method I<get_alt_code> maps characters back to I<Alt+Ch> combinations.

=cut

  func get_alt_char(Int $key_code) {
    return "\0"                                         # no extended key
        if ($key_code & 0xff) == 0;

    my $hi = $key_code >> 8 & 0xff;

    return chr(0xf0)                                    # special case Alt-Space
        if $hi == 0x02;

    if ( $hi <= 0x83 ) {                                # highest value in list
      for my $i (0..127) {                              # search for match
        return chr($hi)                                 # return character
            if $hi == _ALT_CODES->( $i );
      }
    }

    return "\0";
  }

=item public C<< Int get_alt_code(Str $ch) >>

Maps a single character 'A' to 'Z' to the Keycode equivalent value for pressing
I<Alt+Ch>.

For example,

  get_alt_code(Str $ch);

returns C<0x1e00>, which is the value of KB_ALT_A.

The subroutine I<get_alt_code> is the inverse function to I<get_alt_char>.

=cut

  func get_alt_code(Str $ch) {
    $ch = ord( uc($ch) );
    
    return 0x0200
        if $ch == 0xf0;                                 # special case Alt-Space
      
    return _ALT_CODES->($ch) << 8
        if $ch >= 0 && $ch <= 127;

    return 0;
  }

=item public C<< Str get_ctrl_char(Int $key_code) >>

Returns the ASCII character for the I<Ctrl+Key> scancode that was given.

=cut

  func get_ctrl_char(Int $key_code) {
    my $lo = $key_code & 0xff;

    return chr($lo + 0x40)                              # return char a-z
        if $lo >= 1 && $lo <= 26;                       # between 1-26

    return "\0";
  }

=item public C<< Int get_ctrl_code(Str $ch) >>

Returns the scancode corresponding to I<Ctrl+Ch> key that is given.

=cut

  func get_ctrl_code(Str $ch) {
    return get_alt_code($ch) | ord($ch) - 0x40;         # Ctrl+key code
  }

=item public C<< get_key_event(TEvent $event) >>

Emulates the BIOS function INT 16h, Function 01h "Read LowLevel Status" to
determine if a key has been pressed on the keyboard.

If so, I<< $event->what >> is set to I<EV_KEY_DOWN> and I<< $event->key_code >>
is set to the scan code of the key.

If no keys have been pressed, I<< $event->what >> is set to I<EV_NOTHING>.

This is an internal procedure called by I<< TProgram->get_event >>.

See: I<evXXXX> constants

=cut

  func get_key_event($) {
    alias my $event = $_[-1];
    assert { is_TEvent $event };

    _update_event_queue();

    for (my $i = 0; $i < @_event_queue; $i++) {
      $event = $_event_queue[$i];
      assert { is_TEvent $event };

      if ( $event->what & EV_KEYBOARD ) {
        splice(@_event_queue, $i, 1);
        return;
      }
    }

    $event = TEvent->new( what => EV_NOTHING );
    return;
  }

=item public C<< Int get_shift_state() >>

Returns a integer (octal) containing the current Shift key state. The return
value contains a combination of the I<kbXXXX> constants for shift states.

=cut

  func get_shift_state() {
    return $TurboVision::Drivers::Win32::EventQ::_shift_state;
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

=head1 CONTRIBUTOR

=over

=item *

2021-2023 by J. Schneider L<https://github.com/brickpool/>

=back

=head1 SEE ALSO

L<drivers.pas|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/fv/src/drivers.pas>, 
