=pod

=head1 DESCRIPTION

Defines C<EV_*>, C<MB_*>, C<ME_*> and C<SM_*> constants.

Additionally defines constants for all control key combinations (C<KB_*> and 
C<:kbXXXX>).

=cut

package TV::Drivers::Const;

use Exporter 'import';

our @EXPORT_OK = ();

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

  mbXXXX => [qw(
    MB_LEFT_BUTTON
    MB_RIGHT_BUTTON
  )],

  meXXXX => [qw(
    ME_MOUSE_MOVED
    ME_DOUBLE_CLICK
  )],

  smXXXX => [qw(
    SM_BW80
    SM_CO80
    SM_MONO
    SM_FONT_8X8
  )],

  kbXXXX => [qw(
    KB_CTRL_A
    KB_CTRL_B
    KB_CTRL_C
    KB_CTRL_D
    KB_CTRL_E
    KB_CTRL_F
    KB_CTRL_G
    KB_CTRL_H
    KB_CTRL_I
    KB_CTRL_J
    KB_CTRL_K
    KB_CTRL_L
    KB_CTRL_M
    KB_CTRL_N
    KB_CTRL_O
    KB_CTRL_P
    KB_CTRL_Q
    KB_CTRL_R
    KB_CTRL_S
    KB_CTRL_T
    KB_CTRL_U
    KB_CTRL_V
    KB_CTRL_W
    KB_CTRL_X
    KB_CTRL_Y
    KB_CTRL_Z

    KB_ESC
    KB_ALT_SPACE
    KB_CTRL_INS
    KB_SHIFT_INS
    KB_CTRL_DEL
    KB_SHIFT_DEL
    KB_BACK
    KB_CTRL_BACK
    KB_SHIFT_TAB
    KB_TAB
    KB_ALT_Q
    KB_ALT_W
    KB_ALT_E
    KB_ALT_R
    KB_ALT_T
    KB_ALT_Y
    KB_ALT_U
    KB_ALT_I
    KB_ALT_O
    KB_ALT_P
    KB_CTRL_ENTER
    KB_ENTER
    KB_ALT_A
    KB_ALT_S
    KB_ALT_D
    KB_ALT_F
    KB_ALT_G
    KB_ALT_H
    KB_ALT_J
    KB_ALT_K
    KB_ALT_L
    KB_ALT_Z
    KB_ALT_X
    KB_ALT_C
    KB_ALT_V
    KB_ALT_B
    KB_ALT_N
    KB_ALT_M
    KB_F1
    KB_F2
    KB_F3
    KB_F4
    KB_F5
    KB_F6
    KB_F7
    KB_F8
    KB_F9
    KB_F10
    KB_HOME
    KB_UP
    KB_PG_UP
    KB_GRAY_MINUS
    KB_LEFT
    KB_RIGHT
    KB_GRAY_PLUS
    KB_END
    KB_DOWN
    KB_PG_DN
    KB_INS
    KB_DEL
    KB_SHIFT_F1
    KB_SHIFT_F2
    KB_SHIFT_F3
    KB_SHIFT_F4
    KB_SHIFT_F5
    KB_SHIFT_F6
    KB_SHIFT_F7
    KB_SHIFT_F8
    KB_SHIFT_F9
    KB_SHIFT_F10
    KB_CTRL_F1
    KB_CTRL_F2
    KB_CTRL_F3
    KB_CTRL_F4
    KB_CTRL_F5
    KB_CTRL_F6
    KB_CTRL_F7
    KB_CTRL_F8
    KB_CTRL_F9
    KB_CTRL_F10
    KB_ALT_F1
    KB_ALT_F2
    KB_ALT_F3
    KB_ALT_F4
    KB_ALT_F5
    KB_ALT_F6
    KB_ALT_F7
    KB_ALT_F8
    KB_ALT_F9
    KB_ALT_F10
    KB_CTRL_PRT_SC
    KB_CTRL_LEFT
    KB_CTRL_RIGHT
    KB_CTRL_END
    KB_CTRL_PG_DN
    KB_CTRL_HOME
    KB_ALT_1
    KB_ALT_2
    KB_ALT_3
    KB_ALT_4
    KB_ALT_5
    KB_ALT_6
    KB_ALT_7
    KB_ALT_8
    KB_ALT_9
    KB_ALT_0
    KB_ALT_MINUS
    KB_ALT_EQUAL
    KB_CTRL_PG_UP
    KB_ALT_BACK
    KB_NO_KEY

    KB_F11
    KB_F12
    KB_SHIFT_F11
    KB_SHIFT_F12
    KB_CTRL_F11
    KB_CTRL_F12
    KB_ALT_F11
    KB_ALT_F12

    KB_LEFT_SHIFT
    KB_RIGHT_SHIFT
    KB_LEFT_CTRL
    KB_RIGHT_CTRL
    KB_LEFT_ALT
    KB_RIGHT_ALT
    KB_SCROLL_STATE
    KB_NUM_STATE
    KB_CAPS_STATE
    KB_ENHANCED
    KB_INS_STATE

    KB_SHIFT
    KB_CTRL_SHIFT
    KB_ALT_SHIFT
  )],
);

use constant _WINDOWS => $^O eq 'MSWin32';
use if _WINDOWS, 'Win32::Console';

use constant {
  # Event codes
  EV_MOUSE_DOWN   => 0x0001,
  EV_MOUSE_UP     => 0x0002,
  EV_MOUSE_MOVE   => 0x0004,
  EV_MOUSE_AUTO   => 0x0008,
  EV_KEY_DOWN     => 0x0010,
  EV_COMMAND      => 0x0100,
  EV_BROADCAST    => 0x0200,
};

use constant {
  # Event masks
  EV_NOTHING      => 0x0000,
  EV_MOUSE        => 0x000f,
  EV_KEYBOARD     => 0x0010,
  EV_MESSAGE      => 0xFF00,
};

use constant {
  # Mouse button state masks
  MB_LEFT_BUTTON  => 0x01,
  MB_RIGHT_BUTTON => 0x02,
};

use constant {
  # Mouse event flags
  ME_MOUSE_MOVED  => 0x01,
  ME_DOUBLE_CLICK => 0x02,
};

use constant {
  # Display video modes
  SM_BW80      => 0x0002,
  SM_CO80      => 0x0003,
  SM_MONO      => 0x0007,
  SM_FONT_8X8  => 0x0100,
};

# NOTE: these Control key definitions are intended only to provide
# mnemonic names for the ASCII control codes. They cannot be used
# to define menu hotkeys, etc., which require scan codes.
use constant {
  # Control keys
  KB_CTRL_A => 0x0001,
  KB_CTRL_B => 0x0002,
  KB_CTRL_C => 0x0003,
  KB_CTRL_D => 0x0004,
  KB_CTRL_E => 0x0005,
  KB_CTRL_F => 0x0006,
  KB_CTRL_G => 0x0007,
  KB_CTRL_H => 0x0008,
  KB_CTRL_I => 0x0009,
  KB_CTRL_J => 0x000a,
  KB_CTRL_K => 0x000b,
  KB_CTRL_L => 0x000c,
  KB_CTRL_M => 0x000d,
  KB_CTRL_N => 0x000e,
  KB_CTRL_O => 0x000f,
  KB_CTRL_P => 0x0010,
  KB_CTRL_Q => 0x0011,
  KB_CTRL_R => 0x0012,
  KB_CTRL_S => 0x0013,
  KB_CTRL_T => 0x0014,
  KB_CTRL_U => 0x0015,
  KB_CTRL_V => 0x0016,
  KB_CTRL_W => 0x0017,
  KB_CTRL_X => 0x0018,
  KB_CTRL_Y => 0x0019,
  KB_CTRL_Z => 0x001a,

  # Extended key codes
  KB_ESC         => 0x011b,
  KB_ALT_SPACE   => 0x0200,
  KB_CTRL_INS    => 0x0400,
  KB_SHIFT_INS   => 0x0500,
  KB_CTRL_DEL    => 0x0600,
  KB_SHIFT_DEL   => 0x0700,
  KB_BACK        => 0x0e08,
  KB_CTRL_BACK   => 0x0e7f,
  KB_SHIFT_TAB   => 0x0f00,
  KB_TAB         => 0x0f09,
  KB_ALT_Q       => 0x1000,
  KB_ALT_W       => 0x1100,
  KB_ALT_E       => 0x1200,
  KB_ALT_R       => 0x1300,
  KB_ALT_T       => 0x1400,
  KB_ALT_Y       => 0x1500,
  KB_ALT_U       => 0x1600,
  KB_ALT_I       => 0x1700,
  KB_ALT_O       => 0x1800,
  KB_ALT_P       => 0x1900,
  KB_CTRL_ENTER  => 0x1c0a,
  KB_ENTER       => 0x1c0d,
  KB_ALT_A       => 0x1e00,
  KB_ALT_S       => 0x1f00,
  KB_ALT_D       => 0x2000,
  KB_ALT_F       => 0x2100,
  KB_ALT_G       => 0x2200,
  KB_ALT_H       => 0x2300,
  KB_ALT_J       => 0x2400,
  KB_ALT_K       => 0x2500,
  KB_ALT_L       => 0x2600,
  KB_ALT_Z       => 0x2c00,
  KB_ALT_X       => 0x2d00,
  KB_ALT_C       => 0x2e00,
  KB_ALT_V       => 0x2f00,
  KB_ALT_B       => 0x3000,
  KB_ALT_N       => 0x3100,
  KB_ALT_M       => 0x3200,
  KB_F1          => 0x3b00,
  KB_F2          => 0x3c00,
  KB_F3          => 0x3d00,
  KB_F4          => 0x3e00,
  KB_F5          => 0x3f00,
  KB_F6          => 0x4000,
  KB_F7          => 0x4100,
  KB_F8          => 0x4200,
  KB_F9          => 0x4300,
  KB_F10         => 0x4400,
  KB_HOME        => 0x4700,
  KB_UP          => 0x4800,
  KB_PG_UP       => 0x4900,
  KB_GRAY_MINUS  => 0x4a2d,
  KB_LEFT        => 0x4b00,
  KB_RIGHT       => 0x4d00,
  KB_GRAY_PLUS   => 0x4e2b,
  KB_END         => 0x4f00,
  KB_DOWN        => 0x5000,
  KB_PG_DN       => 0x5100,
  KB_INS         => 0x5200,
  KB_DEL         => 0x5300,
  KB_SHIFT_F1    => 0x5400,
  KB_SHIFT_F2    => 0x5500,
  KB_SHIFT_F3    => 0x5600,
  KB_SHIFT_F4    => 0x5700,
  KB_SHIFT_F5    => 0x5800,
  KB_SHIFT_F6    => 0x5900,
  KB_SHIFT_F7    => 0x5a00,
  KB_SHIFT_F8    => 0x5b00,
  KB_SHIFT_F9    => 0x5c00,
  KB_SHIFT_F10   => 0x5d00,
  KB_CTRL_F1     => 0x5e00,
  KB_CTRL_F2     => 0x5f00,
  KB_CTRL_F3     => 0x6000,
  KB_CTRL_F4     => 0x6100,
  KB_CTRL_F5     => 0x6200,
  KB_CTRL_F6     => 0x6300,
  KB_CTRL_F7     => 0x6400,
  KB_CTRL_F8     => 0x6500,
  KB_CTRL_F9     => 0x6600,
  KB_CTRL_F10    => 0x6700,
  KB_ALT_F1      => 0x6800,
  KB_ALT_F2      => 0x6900,
  KB_ALT_F3      => 0x6a00,
  KB_ALT_F4      => 0x6b00,
  KB_ALT_F5      => 0x6c00,
  KB_ALT_F6      => 0x6d00,
  KB_ALT_F7      => 0x6e00,
  KB_ALT_F8      => 0x6f00,
  KB_ALT_F9      => 0x7000,
  KB_ALT_F10     => 0x7100,
  KB_CTRL_PRT_SC => 0x7200,
  KB_CTRL_LEFT   => 0x7300,
  KB_CTRL_RIGHT  => 0x7400,
  KB_CTRL_END    => 0x7500,
  KB_CTRL_PG_DN  => 0x7600,
  KB_CTRL_HOME   => 0x7700,
  KB_ALT_1       => 0x7800,
  KB_ALT_2       => 0x7900,
  KB_ALT_3       => 0x7a00,
  KB_ALT_4       => 0x7b00,
  KB_ALT_5       => 0x7c00,
  KB_ALT_6       => 0x7d00,
  KB_ALT_7       => 0x7e00,
  KB_ALT_8       => 0x7f00,
  KB_ALT_9       => 0x8000,
  KB_ALT_0       => 0x8100,
  KB_ALT_MINUS   => 0x8200,
  KB_ALT_EQUAL   => 0x8300,
  KB_CTRL_PG_UP  => 0x8400,
  KB_ALT_BACK    => 0x0800,
  KB_NO_KEY      => 0x0000,

  KB_F11       => 0x5700,
  KB_F12       => 0x5800,
  KB_SHIFT_F11 => 0x8700,
  KB_SHIFT_F12 => 0x8800,
  KB_CTRL_F11  => 0x8900,
  KB_CTRL_F12  => 0x8A00,
  KB_ALT_F11   => 0x8B00,
  KB_ALT_F12   => 0x8C00,
};

use constant {
  # Keyboard state and shift masks
  KB_LEFT_SHIFT   => _WINDOWS ? Win32::Console::SHIFT_PRESSED()      : 0x0001,
  KB_RIGHT_SHIFT  => _WINDOWS ? Win32::Console::SHIFT_PRESSED()      : 0x0002,
  KB_LEFT_CTRL    => _WINDOWS ? Win32::Console::LEFT_CTRL_PRESSED()  : 0x0004,
  KB_RIGHT_CTRL   => _WINDOWS ? Win32::Console::RIGHT_CTRL_PRESSED() : 0x0004,
  KB_LEFT_ALT     => _WINDOWS ? Win32::Console::LEFT_ALT_PRESSED()   : 0x0008,
  KB_RIGHT_ALT    => _WINDOWS ? Win32::Console::RIGHT_ALT_PRESSED()  : 0x0008,
  KB_SCROLL_STATE => _WINDOWS ? Win32::Console::SCROLLLOCK_ON()      : 0x0010,
  KB_NUM_STATE    => _WINDOWS ? Win32::Console::NUMLOCK_ON()         : 0x0020,
  KB_CAPS_STATE   => _WINDOWS ? Win32::Console::CAPSLOCK_ON()        : 0x0040,
  KB_ENHANCED     => _WINDOWS ? Win32::Console::ENHANCED_KEY()       : undef,
  # Ensure this doesn't overlap above values
  KB_INS_STATE    => _WINDOWS ? 0x200                                : 0x0080,   
};

# On some operating systems, distinguishing between the right and left shift
# keys is not supported, and there is an additional new flag,
# KB_ENHANCED, which is set if the key pressed was an enhanced key
# (e.g. <insert> or <home>)
#
# However, there are additional flags for the right and left
# Control and Alt keys, but this is not supported.  The flags are
# there for source compatibility with the Windows version which does
# support this.
use constant {
  KB_SHIFT      => KB_LEFT_SHIFT | KB_RIGHT_SHIFT,
  KB_CTRL_SHIFT => KB_LEFT_CTRL | KB_RIGHT_CTRL,
  KB_ALT_SHIFT  => KB_LEFT_ALT | KB_RIGHT_ALT,
};

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

1
