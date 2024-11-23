=pod

=head1 DESCRIPTION

Defines C<EV_*>, C<MB_*>, C<ME_*> and C<SM_*> constants.

Additionally defines constants for all control key combinations (C<KB_*> and 
C<:kbXXXX>).

=cut

package TV::Drivers::Const;

use Exporter 'import';

our @EXPORT_OK = qw(
  eventQSize
);

our %EXPORT_TAGS = (
  evXXXX => [qw(
    evMouseDown
    evMouseUp
    evMouseMove
    evMouseAuto
    evKeyDown
    evCommand
    evBroadcast
    evNothing
    evMouse
    evKeyboard
    evMessage
  )],

  mbXXXX => [qw(
    mbLeftButton
    mbRightButton
  )],

  meXXXX => [qw(
    meMouseMoved
    meDoubleClick
  )],

  smXXXX => [qw(
    smBW80
    smCO80
    smMono
    smFont8x8
  )],

  kbXXXX => [qw(
    kbCtrlA
    kbCtrlB
    kbCtrlC
    kbCtrlD
    kbCtrlE
    kbCtrlF
    kbCtrlG
    kbCtrlH
    kbCtrlI
    kbCtrlJ
    kbCtrlK
    kbCtrlL
    kbCtrlM
    kbCtrlN
    kbCtrlO
    kbCtrlP
    kbCtrlQ
    kbCtrlR
    kbCtrlS
    kbCtrlT
    kbCtrlU
    kbCtrlV
    kbCtrlW
    kbCtrlX
    kbCtrlY
    kbCtrlZ

    kbEsc
    kbAltSpace
    kbCtrlIns
    kbShiftIns
    kbCtrlDel
    kbShiftDel
    kbBack
    kbCtrlBack
    kbShiftTab
    kbTab
    kbAltQ
    kbAltW
    kbAltE
    kbAltR
    kbAltT
    kbAltY
    kbAltU
    kbAltI
    kbAltO
    kbAltP
    kbCtrlEnter
    kbEnter
    kbAltA
    kbAltS
    kbAltD
    kbAltF
    kbAltG
    kbAltH
    kbAltJ
    kbAltK
    kbAltL
    kbAltZ
    kbAltX
    kbAltC
    kbAltV
    kbAltB
    kbAltN
    kbAltM
    kbF1
    kbF2
    kbF3
    kbF4
    kbF5
    kbF6
    kbF7
    kbF8
    kbF9
    kbF10
    kbHome
    kbUp
    kbPgUp
    kbGrayMinus
    kbLeft
    kbRight
    kbGrayPlus
    kbEnd
    kbDown
    kbPgDn
    kbIns
    kbDel
    kbShiftF1
    kbShiftF2
    kbShiftF3
    kbShiftF4
    kbShiftF5
    kbShiftF6
    kbShiftF7
    kbShiftF8
    kbShiftF9
    kbShiftF10
    kbCtrlF1
    kbCtrlF2
    kbCtrlF3
    kbCtrlF4
    kbCtrlF5
    kbCtrlF6
    kbCtrlF7
    kbCtrlF8
    kbCtrlF9
    kbCtrlF10
    kbAltF1
    kbAltF2
    kbAltF3
    kbAltF4
    kbAltF5
    kbAltF6
    kbAltF7
    kbAltF8
    kbAltF9
    kbAltF10
    kbCtrlPrtSc
    kbCtrlLeft
    kbCtrlRight
    kbCtrlEnd
    kbCtrlPgDn
    kbCtrlHome
    kbAlt1
    kbAlt2
    kbAlt3
    kbAlt4
    kbAlt5
    kbAlt6
    kbAlt7
    kbAlt8
    kbAlt9
    kbAlt0
    kbAltMinus
    kbAltEqual
    kbCtrlPgUp
    kbAltBack
    kbNoKey

    kbF11
    kbF12
    kbShiftF11
    kbShiftF12
    kbCtrlF11
    kbCtrlF12
    kbAltF11
    kbAltF12

    kbLeftShift
    kbRightShift
    kbLeftCtrl
    kbRightCtrl
    kbLeftAlt
    kbRightAlt
    kbScrollState
    kbNumState
    kbCapsState
    kbEnhanced
    kbInsState

    kbShift
    kbCtrlShift
    kbAltShift
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

use constant _WINDOWS => $^O eq 'MSWin32';
use if _WINDOWS, 'Win32::Console';

use constant {
  eventQSize  => 16,
};

use constant {
  # Event codes
  evMouseDown => 0x0001,
  evMouseUp   => 0x0002,
  evMouseMove => 0x0004,
  evMouseAuto => 0x0008,
  evKeyDown   => 0x0010,
  evCommand   => 0x0100,
  evBroadcast => 0x0200,
};

use constant {
  # Event masks
  evNothing   => 0x0000,
  evMouse     => 0x000f,
  evKeyboard  => 0x0010,
  evMessage   => 0xFF00,
};

use constant {
  # Mouse button state masks
  mbLeftButton  => 0x01,
  mbRightButton => 0x02,
};

use constant {
  # Mouse event flags
  meMouseMoved  => 0x01,
  meDoubleClick => 0x02,
};

use constant {
  # Display video modes
  smBW80    => 0x0002,
  smCO80    => 0x0003,
  smMono    => 0x0007,
  smFont8x8 => 0x0100,
};

# NOTE: these Control key definitions are intended only to provide
# mnemonic names for the ASCII control codes. They cannot be used
# to define menu hotkeys, etc., which require scan codes.
use constant {
  # Control keys
  kbCtrlA => 0x0001,
  kbCtrlB => 0x0002,
  kbCtrlC => 0x0003,
  kbCtrlD => 0x0004,
  kbCtrlE => 0x0005,
  kbCtrlF => 0x0006,
  kbCtrlG => 0x0007,
  kbCtrlH => 0x0008,
  kbCtrlI => 0x0009,
  kbCtrlJ => 0x000a,
  kbCtrlK => 0x000b,
  kbCtrlL => 0x000c,
  kbCtrlM => 0x000d,
  kbCtrlN => 0x000e,
  kbCtrlO => 0x000f,
  kbCtrlP => 0x0010,
  kbCtrlQ => 0x0011,
  kbCtrlR => 0x0012,
  kbCtrlS => 0x0013,
  kbCtrlT => 0x0014,
  kbCtrlU => 0x0015,
  kbCtrlV => 0x0016,
  kbCtrlW => 0x0017,
  kbCtrlX => 0x0018,
  kbCtrlY => 0x0019,
  kbCtrlZ => 0x001a,

  # Extended key codes
  kbEsc       => 0x011b,
  kbAltSpace  => 0x0200,
  kbCtrlIns   => 0x0400,
  kbShiftIns  => 0x0500,
  kbCtrlDel   => 0x0600,
  kbShiftDel  => 0x0700,
  kbBack      => 0x0e08,
  kbCtrlBack  => 0x0e7f,
  kbShiftTab  => 0x0f00,
  kbTab       => 0x0f09,
  kbAltQ      => 0x1000,
  kbAltW      => 0x1100,
  kbAltE      => 0x1200,
  kbAltR      => 0x1300,
  kbAltT      => 0x1400,
  kbAltY      => 0x1500,
  kbAltU      => 0x1600,
  kbAltI      => 0x1700,
  kbAltO      => 0x1800,
  kbAltP      => 0x1900,
  kbCtrlEnter => 0x1c0a,
  kbEnter     => 0x1c0d,
  kbAltA      => 0x1e00,
  kbAltS      => 0x1f00,
  kbAltD      => 0x2000,
  kbAltF      => 0x2100,
  kbAltG      => 0x2200,
  kbAltH      => 0x2300,
  kbAltJ      => 0x2400,
  kbAltK      => 0x2500,
  kbAltL      => 0x2600,
  kbAltZ      => 0x2c00,
  kbAltX      => 0x2d00,
  kbAltC      => 0x2e00,
  kbAltV      => 0x2f00,
  kbAltB      => 0x3000,
  kbAltN      => 0x3100,
  kbAltM      => 0x3200,
  kbF1        => 0x3b00,
  kbF2        => 0x3c00,
  kbF3        => 0x3d00,
  kbF4        => 0x3e00,
  kbF5        => 0x3f00,
  kbF6        => 0x4000,
  kbF7        => 0x4100,
  kbF8        => 0x4200,
  kbF9        => 0x4300,
  kbF10       => 0x4400,
  kbHome      => 0x4700,
  kbUp        => 0x4800,
  kbPgUp      => 0x4900,
  kbGrayMinus => 0x4a2d,
  kbLeft      => 0x4b00,
  kbRight     => 0x4d00,
  kbGrayPlus  => 0x4e2b,
  kbEnd       => 0x4f00,
  kbDown      => 0x5000,
  kbPgDn      => 0x5100,
  kbIns       => 0x5200,
  kbDel       => 0x5300,
  kbShiftF1   => 0x5400,
  kbShiftF2   => 0x5500,
  kbShiftF3   => 0x5600,
  kbShiftF4   => 0x5700,
  kbShiftF5   => 0x5800,
  kbShiftF6   => 0x5900,
  kbShiftF7   => 0x5a00,
  kbShiftF8   => 0x5b00,
  kbShiftF9   => 0x5c00,
  kbShiftF10  => 0x5d00,
  kbCtrlF1    => 0x5e00,
  kbCtrlF2    => 0x5f00,
  kbCtrlF3    => 0x6000,
  kbCtrlF4    => 0x6100,
  kbCtrlF5    => 0x6200,
  kbCtrlF6    => 0x6300,
  kbCtrlF7    => 0x6400,
  kbCtrlF8    => 0x6500,
  kbCtrlF9    => 0x6600,
  kbCtrlF10   => 0x6700,
  kbAltF1     => 0x6800,
  kbAltF2     => 0x6900,
  kbAltF3     => 0x6a00,
  kbAltF4     => 0x6b00,
  kbAltF5     => 0x6c00,
  kbAltF6     => 0x6d00,
  kbAltF7     => 0x6e00,
  kbAltF8     => 0x6f00,
  kbAltF9     => 0x7000,
  kbAltF10    => 0x7100,
  kbCtrlPrtSc => 0x7200,
  kbCtrlLeft  => 0x7300,
  kbCtrlRight => 0x7400,
  kbCtrlEnd   => 0x7500,
  kbCtrlPgDn  => 0x7600,
  kbCtrlHome  => 0x7700,
  kbAlt1      => 0x7800,
  kbAlt2      => 0x7900,
  kbAlt3      => 0x7a00,
  kbAlt4      => 0x7b00,
  kbAlt5      => 0x7c00,
  kbAlt6      => 0x7d00,
  kbAlt7      => 0x7e00,
  kbAlt8      => 0x7f00,
  kbAlt9      => 0x8000,
  kbAlt0      => 0x8100,
  kbAltMinus  => 0x8200,
  kbAltEqual  => 0x8300,
  kbCtrlPgUp  => 0x8400,
  kbAltBack   => 0x0800,
  kbNoKey     => 0x0000,

  kbF11       => 0x5700,
  kbF12       => 0x5800,
  kbShiftF11  => 0x8700,
  kbShiftF12  => 0x8800,
  kbCtrlF11   => 0x8900,
  kbCtrlF12   => 0x8A00,
  kbAltF11    => 0x8B00,
  kbAltF12    => 0x8C00,
};

use constant {
  # Keyboard state and shift masks
  kbLeftShift   => _WINDOWS ? Win32::Console::SHIFT_PRESSED()      : 0x0001,
  kbRightShift  => _WINDOWS ? Win32::Console::SHIFT_PRESSED()      : 0x0002,
  kbLeftCtrl    => _WINDOWS ? Win32::Console::LEFT_CTRL_PRESSED()  : 0x0004,
  kbRightCtrl   => _WINDOWS ? Win32::Console::RIGHT_CTRL_PRESSED() : 0x0004,
  kbLeftAlt     => _WINDOWS ? Win32::Console::LEFT_ALT_PRESSED()   : 0x0008,
  kbRightAlt    => _WINDOWS ? Win32::Console::RIGHT_ALT_PRESSED()  : 0x0008,
  kbScrollState => _WINDOWS ? Win32::Console::SCROLLLOCK_ON()      : 0x0010,
  kbNumState    => _WINDOWS ? Win32::Console::NUMLOCK_ON()         : 0x0020,
  kbCapsState   => _WINDOWS ? Win32::Console::CAPSLOCK_ON()        : 0x0040,
  kbEnhanced    => _WINDOWS ? Win32::Console::ENHANCED_KEY()       : undef,
  # Ensure this doesn't overlap above values
  kbInsState    => _WINDOWS ? 0x200                                : 0x0080,   
};

# On some operating systems, distinguishing between the right and left shift
# keys is not supported, and there is an additional new flag,
# kbEnhanced, which is set if the key pressed was an enhanced key
# (e.g. <insert> or <home>)
#
# However, there are additional flags for the right and left
# Control and Alt keys, but this is not supported.  The flags are
# there for source compatibility with the Windows version which does
# support this.
use constant {
  kbShift     => kbLeftShift | kbRightShift,
  kbCtrlShift => kbLeftCtrl | kbRightCtrl,
  kbAltShift  => kbLeftAlt | kbRightAlt,
};

1
