=pod

=head1 NAME

TurboVision::Drivers::Const - Constants used by I<Drivers>

=head1 SYNOPSIS

  use TurboVision::Drivers::Const qw(
    :smXXXX
  );
  ...

=cut

package TurboVision::Drivers::Const;

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

use Exporter qw( import );

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 EXPORTS

Nothing per default, but can export the following per request:

  :all
    :evXXXX
      EV_MOUSE_DOWN
      EV_MOUSE_UP
      EV_MOUSE_MOVE
      EV_MOUSE_AUTO
      EV_KEY_DOWN
      EV_COMMAND
      EV_BROADCAST

      EV_NOTHING
      EV_MOUSE
      EV_KEYBOARD
      EV_MESSAGE

    :kbXXXX
      KB_RIGHT_SHIFT
      KB_LEFT_SHIFT
      KB_CTRL_SHIFT
      KB_ALT_SHIFT
      KB_SCROLL_STATE
      KB_NUM_STATE
      KB_CAPS_STATE
      KB_INS_STATE

      KB_ALT_A    KB_ALT_N
      KB_ALT_B    KB_ALT_O
      KB_ALT_C    KB_ALT_P
      KB_ALT_D    KB_ALT_Q
      KB_ALT_E    KB_ALT_R
      KB_ALT_F    KB_ALT_S
      KB_ALT_G    KB_ALT_T
      KB_ALT_H    KB_ALT_U
      KB_ALT_I    KB_ALT_V
      KB_ALT_J    KB_ALT_W
      KB_ALT_K    KB_ALT_X
      KB_ALT_L    KB_ALT_Y
      KB_ALT_M    KB_ALT_Z
  
      KB_ALT_EQUAL    KB_END
      KB_ALT_MINUS    KB_ENTER
      KB_ALT_SPACE    KB_ESC
      KB_BACK         KB_GRAY_MINUS
      KB_CTRL_BACK    KB_HOME
      KB_CTRL_DEL     KB_INS
      KB_CTRL_END     KB_LEFT
      KB_CTRL_ENTER   KB_NO_KEY
      KB_CTRL_HOME    KB_PG_DN
      KB_CTRL_INS     KB_PG_UP
      KB_CTRL_LEFT    KB_GRAY_PLUS
      KB_CTRL_PGDN    KB_RIGHT
      KB_CTRL_PGUP    KB_SHIFT_DEL
      KB_CTRL_PRTSC   KB_SHIFT_INS
      KB_CTRL_RIGHT   KB_SHIFT_TAB
      KB_DEL          KB_TAB
      KB_DOWN         KB_UP
  
      KB_ALT_1    KB_ALT_6
      KB_ALT_2    KB_ALT_7
      KB_ALT_3    KB_ALT_8
      KB_ALT_4    KB_ALT_9
      KB_ALT_5    KB_ALT_0
  
      KB_F1   KB_F6
      KB_F2   KB_F7
      KB_F3   KB_F8
      KB_F4   KB_F9
      KB_F5   KB_F10

      KB_SHIFT_F1   KB_SHIFT_F6
      KB_SHIFT_F2   KB_SHIFT_F7
      KB_SHIFT_F3   KB_SHIFT_F8
      KB_SHIFT_F4   KB_SHIFT_F9
      KB_SHIFT_F5   KB_SHIFT_F10

      KB_CTRL_F1    KB_CTRL_F6
      KB_CTRL_F2    KB_CTRL_F7
      KB_CTRL_F3    KB_CTRL_F8
      KB_CTRL_F4    KB_CTRL_F9
      KB_CTRL_F5    KB_CTRL_F10
      
      KB_SHIFT

    :mbXXXX
      MB_LEFT_BUTTON
      MB_RIGHT_BUTTON
      MB_MIDDLE_BUTTON
      MB_SCROLL_WHEEL_DOWN
      MB_SCROLL_WHEEL_UP

    :smXXXX
      SM_BW80
      SM_CO80
      SM_MONO
      SM_FONT8X8

    :private
      _ALT_CODES
      _CP437_TO_UTF8
      _EVENT_Q_SIZE
      _SCREEN_RESOLUTION
      _STANDARD_CRT_MODE
      _WORD_STAR_CODES
      _UTF8_TO_CP437

=cut

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (

  evXXXX => [qw(
    EV_MOUSE_DOWN
    EV_MOUSE_UP
    EV_MOUSE_MOVE
    EV_MOUSE_AUTO
    EV_KEY_DOWN
    EV_COMMAND
    EV_BROADCAST

    EV_NOTHING
    EV_MOUSE
    EV_KEYBOARD
    EV_MESSAGE
  )],

  kbXXXX => [qw(
    KB_RIGHT_SHIFT
    KB_LEFT_SHIFT
    KB_CTRL_SHIFT
    KB_ALT_SHIFT
    KB_SCROLL_STATE
    KB_NUM_STATE
    KB_CAPS_STATE
    KB_INS_STATE

    KB_ALT_A    KB_ALT_N
    KB_ALT_B    KB_ALT_O
    KB_ALT_C    KB_ALT_P
    KB_ALT_D    KB_ALT_Q
    KB_ALT_E    KB_ALT_R
    KB_ALT_F    KB_ALT_S
    KB_ALT_G    KB_ALT_T
    KB_ALT_H    KB_ALT_U
    KB_ALT_I    KB_ALT_V
    KB_ALT_J    KB_ALT_W
    KB_ALT_K    KB_ALT_X
    KB_ALT_L    KB_ALT_Y
    KB_ALT_M    KB_ALT_Z

    KB_ALT_EQUAL    KB_END
    KB_ALT_MINUS    KB_ENTER
    KB_ALT_SPACE    KB_ESC
    KB_BACK         KB_GRAY_MINUS
    KB_CTRL_BACK    KB_HOME
    KB_CTRL_DEL     KB_INS
    KB_CTRL_END     KB_LEFT
    KB_CTRL_ENTER   KB_NO_KEY
    KB_CTRL_HOME    KB_PG_DN
    KB_CTRL_INS     KB_PG_UP
    KB_CTRL_LEFT    KB_GRAY_PLUS
    KB_CTRL_PGDN    KB_RIGHT
    KB_CTRL_PGUP    KB_SHIFT_DEL
    KB_CTRL_PRTSC   KB_SHIFT_INS
    KB_CTRL_RIGHT   KB_SHIFT_TAB
    KB_DEL          KB_TAB
    KB_DOWN         KB_UP

    KB_ALT_1    KB_ALT_6
    KB_ALT_2    KB_ALT_7
    KB_ALT_3    KB_ALT_8
    KB_ALT_4    KB_ALT_9
    KB_ALT_5    KB_ALT_0

    KB_F1   KB_F6
    KB_F2   KB_F7
    KB_F3   KB_F8
    KB_F4   KB_F9
    KB_F5   KB_F10

    KB_SHIFT_F1   KB_SHIFT_F6
    KB_SHIFT_F2   KB_SHIFT_F7
    KB_SHIFT_F3   KB_SHIFT_F8
    KB_SHIFT_F4   KB_SHIFT_F9
    KB_SHIFT_F5   KB_SHIFT_F10

    KB_CTRL_F1    KB_CTRL_F6
    KB_CTRL_F2    KB_CTRL_F7
    KB_CTRL_F3    KB_CTRL_F8
    KB_CTRL_F4    KB_CTRL_F9
    KB_CTRL_F5    KB_CTRL_F10
    
    KB_SHIFT
  )],

  mbXXXX => [qw(
    MB_LEFT_BUTTON
    MB_RIGHT_BUTTON
    MB_MIDDLE_BUTTON
    MB_SCROLL_WHEEL_DOWN
    MB_SCROLL_WHEEL_UP
  )],

  smXXXX => [qw(
    SM_BW80
    SM_CO80
    SM_MONO
    SM_FONT8X8
  )],

  private => [qw(
    _ALT_CODES
    _CP437_TO_UTF8
    _EVENT_Q_SIZE
    _UTF8_TO_CP437
    _SCREEN_RESOLUTION
    _STANDARD_CRT_MODE
    _WORD_STAR_CODES
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

=head1 DESCRIPTION

tbd

=cut

# ------------------------------------------------------------------------
# Constants --------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 CONSTANTS

=head2 Event type masks

=over

=item public const C<< Int EV_MOUSE_DOWN >>

Mouse down event

=cut

  use constant EV_MOUSE_DOWN  => 0x0001;

=item public const C<< Int EV_MOUSE_UP >>

Mouse up event.

=cut

  use constant EV_MOUSE_UP    => 0x0002;

=item public const C<< Int EV_MOUSE_MOVE >>

Mouse move event.

=cut

  use constant EV_MOUSE_MOVE  => 0x0004;

=item public const C<< Int EV_MOUSE_AUTO >>

Mouse movement with pressed key event.

=cut

  use constant EV_MOUSE_AUTO  => 0x0008;

=item public const C<< Int EV_KEY_DOWN >>

Key down event.

=cut

  use constant EV_KEY_DOWN    => 0x0010;

=item public const C<< Int EV_COMMAND >>

Command event.

=cut

  use constant EV_COMMAND     => 0x0100;

=item public const C<< Int EV_BROADCAST >>

Broadcast event.

=cut

  use constant EV_BROADCAST   => 0x0200;

=back

=cut

=head2 Event code masks

=over

=item public const C<< Int EV_NOTHING >>

Empty event

=cut

  use constant EV_NOTHING   => 0x0000;

=item public const C<< Int EV_MOUSE >>

Mouse event.

=cut

  use constant EV_MOUSE     => 0x000f;

=item public const C<< Int EV_KEYBOARD >>

Keyboard event.

=cut

  use constant EV_KEYBOARD  => 0x0010;

=item public const C<< Int EV_MESSAGE >>

Message event.

=cut

  use constant EV_MESSAGE   => 0xff00;

=back

=cut

=head2 Keyboard Shift State Constants

The I<kbXXXX> constants for detecting keyboard shift states.

The keyboard shift state constants are used as a bit mask to test the status of
various keyboard keys, such as the Ctrl or Shift key.

For example, to see if the keyboard is producing shifted characters, declare an
subroutine and test the bits like this:

    sub shift_state;
    ...
    if ( shift_state & ( kbRightShift | kbLeftShift | kbCapsState ) ) {
      ...

=over

=item public const C<< Int KB_RIGHT_SHIFT >>

Bit set if the right shift key down.

=cut

  use constant KB_RIGHT_SHIFT   => 0x0001;

=item public const C<< Int KB_LEFT_SHIFT >>

Bit set if the left shift key down.

=cut

  use constant KB_LEFT_SHIFT    => 0x0002;

=item public const C<< Int KB_CTRL_SHIFT >>

Bit set if the Ctrl key is down.

=cut

  use constant KB_CTRL_SHIFT    => 0x0004;

=item public const C<< Int KB_ALT_SHIFT >>

Bit set if the Alt key is down.

=cut

  use constant KB_ALT_SHIFT     => 0x0008;

=item public const C<< Int KB_SCROLL_STATE >>

Bit set if the Scroll Lock is down.

=cut

  use constant KB_SCROLL_STATE  => 0x0010;

=item public const C<< Int KB_NUM_STATE >>

Bit set if the Num Lock is down.

=cut

  use constant KB_NUM_STATE     => 0x0020;

=item public const C<< Int KB_CAPS_STATE >>

Bit set if the Caps Lock down.

=cut

  use constant KB_CAPS_STATE    => 0x0040;

=item public const C<< Int KB_INS_STATE >>

Bit set if keyboard is in Ins Lock state.

=cut

  use constant KB_INS_STATE     => 0x0080;

=back

=cut

=head2 Keyboard Scancode Constants

The I<kbXXXX> constants for the non-standard keystrokes such as function and Alt
keys.

Use these constants to check for specific keystroke values in the
I<< TEvent->key_code >> field. For example,

  if ( $event->key_code == KB_PG_DN ) {
    # handle page down function
    ...

=over

=item Alt-Ch key code constants

  Constant    Value     Constant    Value
  KB_ALT_A    0x1e00    KB_ALT_N    0x3100
  KB_ALT_B    0x3000    KB_ALT_O    0x1800
  KB_ALT_C    0x2e00    KB_ALT_P    0x1900
  KB_ALT_D    0x2000    KB_ALT_Q    0x1000
  KB_ALT_E    0x1200    KB_ALT_R    0x1300
  KB_ALT_F    0x2100    KB_ALT_S    0x1f00
  KB_ALT_G    0x2200    KB_ALT_T    0x1400
  KB_ALT_H    0x2300    KB_ALT_U    0x1600
  KB_ALT_I    0x1700    KB_ALT_V    0x2f00
  KB_ALT_J    0x2400    KB_ALT_W    0x1100
  KB_ALT_K    0x2500    KB_ALT_X    0x2d00
  KB_ALT_L    0x2600    KB_ALT_Y    0x1500
  KB_ALT_M    0x3200    KB_ALT_Z    0x2c00

=cut

  use constant {
    KB_ALT_A => 0x1e00,   KB_ALT_N => 0x3100,
    KB_ALT_B => 0x3000,   KB_ALT_O => 0x1800,
    KB_ALT_C => 0x2e00,   KB_ALT_P => 0x1900,
    KB_ALT_D => 0x2000,   KB_ALT_Q => 0x1000,
    KB_ALT_E => 0x1200,   KB_ALT_R => 0x1300,
    KB_ALT_F => 0x2100,   KB_ALT_S => 0x1f00,
    KB_ALT_G => 0x2200,   KB_ALT_T => 0x1400,
    KB_ALT_H => 0x2300,   KB_ALT_U => 0x1600,
    KB_ALT_I => 0x1700,   KB_ALT_V => 0x2f00,
    KB_ALT_J => 0x2400,   KB_ALT_W => 0x1100,
    KB_ALT_K => 0x2500,   KB_ALT_X => 0x2d00,
    KB_ALT_L => 0x2600,   KB_ALT_Y => 0x1500,
    KB_ALT_M => 0x3200,   KB_ALT_Z => 0x2c00,
  };

=item Ctrl and special key code constants

  Constant      Value     Constant      Value
  KB_ALT_EQUAL  0x8300    KB_END        0x4F00
  KB_ALT_MINUS  0x8200    KB_ENTER      0x1c0d
  KB_ALT_SPACE  0x0200    KB_ESC        0x011b
  KB_BACK       0x0E08    KB_GRAY_MINUS 0x4a2d *
  KB_CTRL_BACK  0x0e7f    KB_HOME       0x4700
  KB_CTRL_DEL   0x0600    KB_INS        0x5200
  KB_CTRL_END   0x7500    KB_LEFT       0x4b00 *
  KB_CTRL_ENTER 0x1c0a    KB_NO_KEY     0x0000
  KB_CTRL_HOME  0x7700    KB_PG_DN      0x5100
  KB_CTRL_INS   0x0400    KB_PG_UP      0x4900
  KB_CTRL_LEFT  0x7300    KB_GRAY_PLUS  0x4e2b *
  KB_CTRL_PGDN  0x7600    KB_RIGHT      0x4d00 *
  KB_CTRL_PGUP  0x8400    KB_SHIFT_DEL  0x0700
  KB_CTRL_PRTSC 0x7200    KB_SHIFT_INS  0x0500
  KB_CTRL_RIGHT 0x7400    KB_SHIFT_TAB  0x0f00
  KB_DEL        0x5300    KB_TAB        0x0f09
  KB_DOWN       0x5000    KB_UP         0x4800

C<[*]> I<KB_GRAY_MINUS> and I<KB_GRAY_PLUS> are the C<-> and C<+> keys on the
numeric keypad. I<KB_LEFT> and I<KB_RIGHT> are the arrow keys.

=cut

  use constant {
    KB_ALT_EQUAL  => 0x8300,    KB_END        => 0x4F00,
    KB_ALT_MINUS  => 0x8200,    KB_ENTER      => 0x1c0d,
    KB_ALT_SPACE  => 0x0200,    KB_ESC        => 0x011b,
    KB_BACK       => 0x0E08,    KB_GRAY_MINUS => 0x4a2d,
    KB_CTRL_BACK  => 0x0e7f,    KB_HOME       => 0x4700,
    KB_CTRL_DEL   => 0x0600,    KB_INS        => 0x5200,
    KB_CTRL_END   => 0x7500,    KB_LEFT       => 0x4b00,
    KB_CTRL_ENTER => 0x1c0a,    KB_NO_KEY     => 0x0000,
    KB_CTRL_HOME  => 0x7700,    KB_PG_DN      => 0x5100,
    KB_CTRL_INS   => 0x0400,    KB_PG_UP      => 0x4900,
    KB_CTRL_LEFT  => 0x7300,    KB_GRAY_PLUS  => 0x4e2b,
    KB_CTRL_PGDN  => 0x7600,    KB_RIGHT      => 0x4d00,
    KB_CTRL_PGUP  => 0x8400,    KB_SHIFT_DEL  => 0x0700,
    KB_CTRL_PRTSC => 0x7200,    KB_SHIFT_INS  => 0x0500,
    KB_CTRL_RIGHT => 0x7400,    KB_SHIFT_TAB  => 0x0f00,
    KB_DEL        => 0x5300,    KB_TAB        => 0x0f09,
    KB_DOWN       => 0x5000,    KB_UP         => 0x4800,
  };

=item Alt-number key code constants

  Constant    Value     Constant    Value
  KB_ALT_1    0x7800    KB_ALT_6    0x7D00
  KB_ALT_2    0x7900    KB_ALT_7    0x7e00
  KB_ALT_3    0x7a00    KB_ALT_8    0x7f00
  KB_ALT_4    0x7b00    KB_ALT_9    0x8000
  KB_ALT_5    0x7c00    KB_ALT_0    0x8100

=cut

  use constant {
    KB_ALT_1 => 0x7800,   KB_ALT_6 => 0x7D00,
    KB_ALT_2 => 0x7900,   KB_ALT_7 => 0x7e00,
    KB_ALT_3 => 0x7a00,   KB_ALT_8 => 0x7f00,
    KB_ALT_4 => 0x7b00,   KB_ALT_9 => 0x8000,
    KB_ALT_5 => 0x7c00,   KB_ALT_0 => 0x8100,
  };

=item Function key code constants

  Constant  Value     Constant  Value
  KB_F1     0x3b00    KB_F6     0x4000
  KB_F2     0x3c00    KB_F7     0x4100
  KB_F3     0x3d00    KB_F8     0x4200
  KB_F4     0x3e00    KB_F9     0x4300
  KB_F5     0x3f00    KB_F10    0x4400

=cut

  use constant {
    KB_F1 => 0x3b00,    KB_F6   => 0x4000,
    KB_F2 => 0x3c00,    KB_F7   => 0x4100,
    KB_F3 => 0x3d00,    KB_F8   => 0x4200,
    KB_F4 => 0x3e00,    KB_F9   => 0x4300,
    KB_F5 => 0x3f00,    KB_F10  => 0x4400,
  };

=item Shift-function key code constants

  Constant      Value     Constant      Value
  KB_SHIFT_F1   0x5400    KB_SHIFT_F6   0x5900
  KB_SHIFT_F2   0x5500    KB_SHIFT_F7   0x5a00
  KB_SHIFT_F3   0x5600    KB_SHIFT_F8   0x5b00
  KB_SHIFT_F4   0x5700    KB_SHIFT_F9   0x5c00
  KB_SHIFT_F5   0x5800    KB_SHIFT_F10  0x5d00

=cut

  use constant {
    KB_SHIFT_F1 => 0x5400,    KB_SHIFT_F6   => 0x5900,
    KB_SHIFT_F2 => 0x5500,    KB_SHIFT_F7   => 0x5a00,
    KB_SHIFT_F3 => 0x5600,    KB_SHIFT_F8   => 0x5b00,
    KB_SHIFT_F4 => 0x5700,    KB_SHIFT_F9   => 0x5c00,
    KB_SHIFT_F5 => 0x5800,    KB_SHIFT_F10  => 0x5d00,
  };

=item Ctrl-function key code constants

  Constant      Value     Constant      Value
  KB_CTRL_F1    0x5e00    KB_CTRL_F6    0x6300
  KB_CTRL_F2    0x5f00    KB_CTRL_F7    0x6400
  KB_CTRL_F3    0x6000    KB_CTRL_F8    0x6500
  KB_CTRL_F4    0x6100    KB_CTRL_F9    0x6600
  KB_CTRL_F5    0x6200    KB_CTRL_F10   0x6700

=cut

  use constant {
    KB_CTRL_F1 => 0x5e00,   KB_CTRL_F6  => 0x6300,
    KB_CTRL_F2 => 0x5f00,   KB_CTRL_F7  => 0x6400,
    KB_CTRL_F3 => 0x6000,   KB_CTRL_F8  => 0x6500,
    KB_CTRL_F4 => 0x6100,   KB_CTRL_F9  => 0x6600,
    KB_CTRL_F5 => 0x6200,   KB_CTRL_F10 => 0x6700,
  };

=item Alt-function key codes

  Constant      Value     Constant      Value
  KB_ALT_F1     0x6800    KB_ALT_F6     0x6d00
  KB_ALT_F2     0x6900    KB_ALT_F7     0x6e00
  KB_ALT_F3     0x6a00    KB_ALT_F8     0x6f00
  KB_ALT_F4     0x6b00    KB_ALT_F9     0x7000
  KB_ALT_F5     0x6c00    KB_ALT_F10    0x7100

=cut

  use constant {
    KB_ALT_F1 => 0x6800,    KB_ALT_F6   => 0x6d00,
    KB_ALT_F2 => 0x6900,    KB_ALT_F7   => 0x6e00,
    KB_ALT_F3 => 0x6a00,    KB_ALT_F8   => 0x6f00,
    KB_ALT_F4 => 0x6b00,    KB_ALT_F9   => 0x7000,
    KB_ALT_F5 => 0x6c00,    KB_ALT_F10  => 0x7100,
  };

=item Additional key(s) not initially defined by Borland.

  Constant  Value
  KB_SHIFT  KB_RIGHT_SHIFT | KB_LEFT_SHIFT

=cut

  use constant {
    KB_SHIFT => KB_RIGHT_SHIFT | KB_LEFT_SHIFT
  };

=back

=cut

=head2 Mouse Button constants

The I<mbXXXX> constants are used to test the I<< $event->buttons >> field of a
I< TEvent > record or the I<$mouse_buttons> variable to determine if the left or
right button was pressed.

=over

=item public const C<< Int MB_LEFT_BUTTON >>

Value if leftmost mouse button was pressed.

=cut

  use constant MB_LEFT_BUTTON       => 0x01;

=item public const C<< Int MB_RIGHT_BUTTON >>

Value if the rightmost mouse button was presseed.

=cut

  use constant MB_RIGHT_BUTTON      => 0x02;

=item public const C<< Int MB_RIGHT_BUTTON >>

Value if second button from the left was presseed.

=cut

  use constant MB_MIDDLE_BUTTON     => 0x04;

=item public const C<< Int MB_SCROLL_WHEEL_DOWN >>

Scroll wheel down.

=cut

  use constant MB_SCROLL_WHEEL_DOWN => 0x08;

=item public const C<< Int MB_SCROLL_WHEEL_UP >>

Scroll wheel up.

=cut

  use constant MB_SCROLL_WHEEL_UP   => 0x10;

=back

=cut

=head2 Screen Mode Constants

Use the constants from the table below when selecting Black & White, Color or
Monochrome color palettes, or switching between 25 and 43- or 50 line display
modes.

=over

=item public const C<< Int SM_BW40 >>

Black and white/gray scale, 40x25 chars.

=cut

  use constant SM_BW40    => 0x0000;

=item public const C<< Int SM_CO40 >>

Color mode, 40x25 chars.

=cut
 
  use constant SM_CO40    => 0x0001;

=item public const C<< Int SM_BW80 >>

Black and white/gray scale, 80x25 chars.

=cut

  use constant SM_BW80    => 0x0002;

=item public const C<< Int SM_CO80 >>

Color mode, 80x25 chars.

=cut
 
  use constant SM_CO80    => 0x0003;

=item public const C<< Int SM_MONO >>

Monochrome mode, 80x25 chars.

=cut
 
  use constant SM_MONO    => 0x0004;

=item public const C<< Int SM_FONT8X8 >>

43 or 50 line modes.

=cut
 
  use constant SM_FONT8X8 => 0x0100;

=back

=cut

=head2 Drivers used private constants.

=over

=item private const C<< Ref _ALT_CODES >>

Mapping table for I<get_alt_code> and I<get_alt_char>.

=cut

  use constant _ALT_CODES => sub {+[
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,       # 0x00 - 0x07
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,       # 0x08 - 0x0f
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,       # 0x10 - 0x17
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,       # 0x18 - 0x1f
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,       # 0x20 - 0x27
    0x00, 0x00, 0x00, 0x00, 0x00, 0x82, 0x00, 0x00,       # 0x28 - 0x2f
    0x81, 0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0x7e,       # 0x30 - 0x37
    0x7f, 0x80, 0x00, 0x00, 0x00, 0x83, 0x00, 0x00,       # 0x38 - 0x3f
    0x00, 0x1e, 0x30, 0x2e, 0x20, 0x12, 0x21, 0x22,       # 0x40 - 0x47
    0x23, 0x17, 0x24, 0x25, 0x26, 0x32, 0x31, 0x18,       # 0x48 - 0x4f
    0x19, 0x10, 0x13, 0x1f, 0x14, 0x16, 0x2f, 0x11,       # 0x50 - 0x57
    0x2d, 0x15, 0x2c, 0x00, 0x00, 0x00, 0x00, 0x00,       # 0x58 - 0x5f
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,       # 0x60 - 0x67
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,       # 0x68 - 0x6f
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,       # 0x70 - 0x77
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,       # 0x78 - 0x7f
  ]->[ +shift ]};
  
=item private const C<< Ref _CP437_TO_UTF8 >>

Codepage 437 to Unicode translation map.

=cut

  use constant _CP437_TO_UTF8 => sub {+[
    ord "\x{2007}", ord "\x{263a}", ord "\x{263b}", ord "\x{2665}",
    ord "\x{2666}", ord "\x{2663}", ord "\x{2660}", ord "\x{2022}",
    ord "\x{25d8}", ord "\x{25cb}", ord "\x{25d9}", ord "\x{2642}",
    ord "\x{2640}", ord "\x{266a}", ord "\x{266b}", ord "\x{263c}",
  # Termius has 25b6 and 25c0 here, which are better unicode equivalents.
  # ord "\x{25ba}", ord "\x{25c4}", ord "\x{2195}", ord "\x{203c}",
    ord "\x{25b6}", ord "\x{25c0}", ord "\x{2195}", ord "\x{203c}",
    ord "\x{00b6}", ord "\x{00a7}", ord "\x{25ac}", ord "\x{21a8}",
    ord "\x{2191}", ord "\x{2193}", ord "\x{2192}", ord "\x{2190}",
    ord "\x{221f}", ord "\x{2194}", ord "\x{25b2}", ord "\x{25bc}",
    ord "\x{0020}", ord "\x{0021}", ord "\x{0022}", ord "\x{0023}",
    ord "\x{0024}", ord "\x{0025}", ord "\x{0026}", ord "\x{0027}",
    ord "\x{0028}", ord "\x{0029}", ord "\x{002a}", ord "\x{002b}",
    ord "\x{002c}", ord "\x{002d}", ord "\x{002e}", ord "\x{002f}",
    ord "\x{0030}", ord "\x{0031}", ord "\x{0032}", ord "\x{0033}",
    ord "\x{0034}", ord "\x{0035}", ord "\x{0036}", ord "\x{0037}",
    ord "\x{0038}", ord "\x{0039}", ord "\x{003a}", ord "\x{003b}",
    ord "\x{003c}", ord "\x{003d}", ord "\x{003e}", ord "\x{003f}",
    ord "\x{0040}", ord "\x{0041}", ord "\x{0042}", ord "\x{0043}",
    ord "\x{0044}", ord "\x{0045}", ord "\x{0046}", ord "\x{0047}",
    ord "\x{0048}", ord "\x{0049}", ord "\x{004a}", ord "\x{004b}",
    ord "\x{004c}", ord "\x{004d}", ord "\x{004e}", ord "\x{004f}",
    ord "\x{0050}", ord "\x{0051}", ord "\x{0052}", ord "\x{0053}",
    ord "\x{0054}", ord "\x{0055}", ord "\x{0056}", ord "\x{0057}",
    ord "\x{0058}", ord "\x{0059}", ord "\x{005a}", ord "\x{005b}",
    ord "\x{005c}", ord "\x{005d}", ord "\x{005e}", ord "\x{005f}",
    ord "\x{0060}", ord "\x{0061}", ord "\x{0062}", ord "\x{0063}",
    ord "\x{0064}", ord "\x{0065}", ord "\x{0066}", ord "\x{0067}",
    ord "\x{0068}", ord "\x{0069}", ord "\x{006a}", ord "\x{006b}",
    ord "\x{006c}", ord "\x{006d}", ord "\x{006e}", ord "\x{006f}",
    ord "\x{0070}", ord "\x{0071}", ord "\x{0072}", ord "\x{0073}",
    ord "\x{0074}", ord "\x{0075}", ord "\x{0076}", ord "\x{0077}",
    ord "\x{0078}", ord "\x{0079}", ord "\x{007a}", ord "\x{007b}",
    ord "\x{007c}", ord "\x{007d}", ord "\x{007e}", ord "\x{2302}",
    ord "\x{00c7}", ord "\x{00fc}", ord "\x{00e9}", ord "\x{00e2}",
    ord "\x{00e4}", ord "\x{00e0}", ord "\x{00e5}", ord "\x{00e7}",
    ord "\x{00ea}", ord "\x{00eb}", ord "\x{00e8}", ord "\x{00ef}",
    ord "\x{00ee}", ord "\x{00ec}", ord "\x{00c4}", ord "\x{00c5}",
    ord "\x{00c9}", ord "\x{00e6}", ord "\x{00c6}", ord "\x{00f4}",
    ord "\x{00f6}", ord "\x{00f2}", ord "\x{00fb}", ord "\x{00f9}",
    ord "\x{00ff}", ord "\x{00d6}", ord "\x{00dc}", ord "\x{00a2}",
    ord "\x{00a3}", ord "\x{00a5}", ord "\x{20a7}", ord "\x{0192}",
    ord "\x{00e1}", ord "\x{00ed}", ord "\x{00f3}", ord "\x{00fa}",
    ord "\x{00f1}", ord "\x{00d1}", ord "\x{00aa}", ord "\x{00ba}",
    ord "\x{00bf}", ord "\x{2310}", ord "\x{00ac}", ord "\x{00bd}",
    ord "\x{00bc}", ord "\x{00a1}", ord "\x{00ab}", ord "\x{00bb}",
    ord "\x{2591}", ord "\x{2592}", ord "\x{2593}", ord "\x{2502}",
    ord "\x{2524}", ord "\x{2561}", ord "\x{2562}", ord "\x{2556}",
    ord "\x{2555}", ord "\x{2563}", ord "\x{2551}", ord "\x{2557}",
    ord "\x{255d}", ord "\x{255c}", ord "\x{255b}", ord "\x{2510}",
    ord "\x{2514}", ord "\x{2534}", ord "\x{252c}", ord "\x{251c}",
    ord "\x{2500}", ord "\x{253c}", ord "\x{255e}", ord "\x{255f}",
    ord "\x{255a}", ord "\x{2554}", ord "\x{2569}", ord "\x{2566}",
    ord "\x{2560}", ord "\x{2550}", ord "\x{256c}", ord "\x{2567}",
    ord "\x{2568}", ord "\x{2564}", ord "\x{2565}", ord "\x{2559}",
    ord "\x{2558}", ord "\x{2552}", ord "\x{2553}", ord "\x{256b}",
    ord "\x{256a}", ord "\x{2518}", ord "\x{250c}", ord "\x{2588}",
    ord "\x{2584}", ord "\x{258c}", ord "\x{2590}", ord "\x{2580}",
    ord "\x{03b1}", ord "\x{00df}", ord "\x{0393}", ord "\x{03c0}",
    ord "\x{03a3}", ord "\x{03c3}", ord "\x{00b5}", ord "\x{03c4}",
    ord "\x{03a6}", ord "\x{0398}", ord "\x{03a9}", ord "\x{03b4}",
    ord "\x{221e}", ord "\x{03c6}", ord "\x{03b5}", ord "\x{2229}",
    ord "\x{2261}", ord "\x{00b1}", ord "\x{2265}", ord "\x{2264}",
    ord "\x{2320}", ord "\x{2321}", ord "\x{00f7}", ord "\x{2248}",
    ord "\x{00b0}", ord "\x{2219}", ord "\x{00b7}", ord "\x{221a}",
    ord "\x{207f}", ord "\x{00b2}", ord "\x{25a0}", ord "\x{00a0}",
  ]->[ +shift ]};

=item private const C<< Int _EVENT_Q_SIZE >>

Event manager constant for the queue size.

=cut

  use constant _EVENT_Q_SIZE => 16;

=item private const C<< Ref _SCREEN_RESOLUTION >>

Hash constants for converting standard video text modes (C<0x0000..0x00ff>,
C<0x0100..0x07ff> or C<0x0900..0x09ff>) to resolution modes (C<0x1000..0x7fff>).

The code has a I<0xHHWW> form where I<HH> is a number of rows and I<WW> is a
number of columns.

=cut

  use constant _SCREEN_RESOLUTION => sub {+{
    # Possible standard combinations
     SM_BW40()              => 40 | 25 << 8,            # VGA, 16 gray, 9x16
     SM_CO40()              => 40 | 25 << 8,            # VGA, 16 colors, 9x16
     SM_BW80()              => 80 | 25 << 8,            # VGA, 16 gray, 9x16
     SM_CO80()              => 80 | 25 << 8,            # VGA, 16 colors, 9x16
     SM_MONO()              => 80 | 25 << 8,            # MDA, mono, 9x14
    (SM_BW40 + SM_FONT8X8)  => 40 | 25 << 8,            # CGA, 16 gray, 8x8
    (SM_CO40 + SM_FONT8X8)  => 40 | 25 << 8,            # CGA, 16 colors, 8x8
    (SM_BW80 + SM_FONT8X8)  => 80 | 25 << 8,            # CGA, 16 gray, 8x8
    (SM_CO80 + SM_FONT8X8)  => 80 | 50 << 8,            # VGA, 16 colors, 8x8

    #-- Other video BIOS modes, are not used
    # https://en.wikipedia.org/wiki/VGA_text_mode#PC_common_text_modes
    #+0x108  =>  80 | 60 << 8,                           # VESA Text mode
    #+0x109  => 132 | 25 << 8,                           # VESA Text mode
    #+0x10a  => 132 | 43 << 8,                           # VESA Text mode
    #+0x10b  => 132 | 50 << 8,                           # VESA Text mode
    #+0x10c  => 132 | 60 << 8,                           # VESA Text mode
    #
    #+0x43   =>  80 | 60 << 8,                           # Video7 V-RAM VGA
    #+0x44   => 100 | 60 << 8,                           # Video7 V-RAM VGA
    #+0x41   => 132 | 25 << 8,                           # Video7 V-RAM VGA
    #+0x42   => 132 | 43 << 8,                           # Video7 V-RAM VGA
    #
    #+0x0940 =>  80 | 43 << 8,                           # Video7 special mode
    #+0x0943 =>  80 | 60 << 8,                           # Video7 special mode
    #+0x0944 => 100 | 60 << 8,                           # Video7 special mode
    #+0x0941 => 132 | 25 << 8,                           # Video7 special mode
    #+0x0945 => 132 | 28 << 8,                           # Video7 special mode
    #+0x0942 => 132 | 44 << 8,                           # Video7 special mode
    #
    #+0x17   =>  80 | 43 << 8,                           # Tseng ET4000
    #+0x26   =>  80 | 60 << 8,                           # Tseng ET3000/4000
    #+0x2a   => 100 | 40 << 8,                           # Tseng ET4000
    #+0x23   => 132 | 25 << 8,                           # Tseng ET4000
    #+0x24   => 132 | 28 << 8,                           # Tseng ET4000
    #+0x1a   => 132 | 28 << 8,                           # Tseng ET4000
    #+0x22   => 132 | 44 << 8,                           # Tseng ET4000
    #+0x21   => 132 | 60 << 8,                           # Tseng ET4000
    #
    #+0x58   =>  80 | 33 << 8,                           # ATI EGA Wonder
    #+0x27   => 132 | 25 << 8,                           # ATI EGA Wonder
    #+0x33   => 132 | 44 << 8,                           # ATI EGA Wonder
    #+0x37   => 132 | 44 << 8,                           # ATI EGA Wonder
  }->{ +shift }};

=item private const C<< Ref _STANDARD_CRT_MODE >>

Hash constants for converting resolution modes (C<0x1000..0x7fff>) to standard
text modes (C<0x0000..0x00ff>, C<0x0100..0x07ff> or C<0x0900..0x09ff>).

=cut

  use constant _STANDARD_CRT_MODE => sub {+{
    ( 40 | 25 << 8) => SM_CO40,                         # VGA, 16 colors, 9x16
    ( 80 | 25 << 8) => SM_CO80,                         # VGA, 16 colors, 9x16
    ( 80 | 50 << 8) => SM_CO80 + SM_FONT8X8,            # VGA, 16 colors, 8x8

    #-- Other common resolution, are not used
    #( 80 | 60 << 8) => 0x108,                           # VESA Text 0x108
    #(132 | 25 << 8) => 0x109,                           # VESA Text 0x109
    #(132 | 43 << 8) => 0x10a,                           # VESA Text 0x10A
    #(132 | 50 << 8) => 0x10b,                           # VESA Text 0x10B
    #(132 | 60 << 8) => 0x10c,                           # VESA Text 0x10C
    #
    #( 80 | 43 << 8) => 0x0940,                          # Video7 special mode
    #(100 | 60 << 8) => 0x0944,                          # Video7 special mode
    #(132 | 28 << 8) => 0x0945,                          # Video7 special mode
    #(132 | 44 << 8) => 0x0942,                          # Video7 special mode
  }->{ +shift }};

=item private const C<< Ref _WORD_STAR_CODES >>

Hash constants for converting WordStar keystrokes (C<Ctrl-A>, C<Ctrl-X>, ...)
into the corresponding I<kbXXXX> values.

=cut

  use constant _WORD_STAR_CODES => sub {+{
    0x01 => KB_HOME,                                    # Ctrl-A
    0x03 => KB_PG_DN,                                   # Ctrl-C
    0x04 => KB_RIGHT,                                   # Ctrl-D
    0x05 => KB_UP,                                      # Ctrl-E
    0x06 => KB_END,                                     # Ctrl-F
    0x07 => KB_DEL,                                     # Ctrl-G
    0x08 => KB_BACK,                                    # Ctrl-H
    0x12 => KB_PG_UP,                                   # Ctrl-R
    0x13 => KB_LEFT,                                    # Ctrl-S
    0x16 => KB_INS,                                     # Ctrl-V
    0x18 => KB_DOWN,                                    # Ctrl-X
  }->{ +shift }};

=item private const C<< Ref _UTF8_TO_CP437 >>

Unicode to Codepage 437 translation map.

=cut

  use constant _UTF8_TO_CP437 => sub {
    state $from_utf8 = { map { _CP437_TO_UTF8->($_) => $_ } (0..255) };

    my $cp = shift;
    # Support the official Unicode values instead only the Termius equivalents
    return 0x10 if $cp == ord "\x{25ba}";
    return 0x11 if $cp == ord "\x{25c4}";

    return exists $from_utf8->{$cp} ? $from_utf8->{$cp} : 0;
  };

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

2021-2022 by J. Schneider L<https://github.com/brickpool/>

=back

=head1 SEE ALSO

I<Exporter>, I<Drivers>, 
L<drivers.pas|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/fv/src/drivers.pas>
