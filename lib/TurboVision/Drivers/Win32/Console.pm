=pod

=head1 NAME

TurboVision::Drivers::Win32::Console - Windows low level implementation

=head1 SYNOPSIS

Simply integrate this module into your package or script.

  use Win32::Console;
  use TurboVision::Drivers::Win32::Console;

Note: Loading this module must be done after C<use Win32::Console>, otherwise
the extensions and patches for I<Win32::Console> will not be installed
correctly.

=cut

package TurboVision::Drivers::Win32::Console;

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
our $AUTHORITY = 'github:brickpool';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use English qw( -no_match_vars );
use List::Util qw( min max );

use Class::MOP::Package;

use Win32::API;
use Win32::Console;
use Win32API::File;

# ------------------------------------------------------------------------
# Imports ----------------------------------------------------------------
# ------------------------------------------------------------------------

BEGIN {
  use constant kernelDll => 'kernel32';

  Win32::API::Struct->typedef(
    COORD => qw(
      SHORT X;
      SHORT Y;
    )
  );
  Win32::API::Struct->typedef(
    CONSOLE_FONT_INFO => qw(
      DWORD nFont;
      COORD dwFontSize;
    )
  );

  Win32::API::Struct->typedef(
    KEY_EVENT_RECORD => qw(
      WORD  EventType;
      BOOL  bKeyDown;
      WORD  wRepeatCount;
      WORD  wVirtualKeyCode;
      WORD  wVirtualScanCode;
      WCHAR UnicodeChar;
      DWORD dwControlKeyState;
    )
  );

  Win32::API::More->Import(kernelDll, 
    'BOOL GetCurrentConsoleFont(
      HANDLE              hConsoleOutput,
      BOOL                bMaximumWindow,
      LPCONSOLE_FONT_INFO lpConsoleCurrentFont
    )'
  ) or die "Import GetCurrentConsoleFont: $EXTENDED_OS_ERROR";
  
  Win32::API::More->Import(kernelDll, 
    'BOOL PeekConsoleInput(
      HANDLE              hConsoleInput,
      LPKEY_EVENT_RECORD  lpBuffer,
      DWORD               nLength,
      LPDWORD             lpNumberOfEventsRead
    )'
  ) or die "Import ReadConsoleInput: $EXTENDED_OS_ERROR";

  Win32::API::More->Import(kernelDll, 
    'BOOL ReadConsoleInputW(
      HANDLE              hConsoleInput,
      LPKEY_EVENT_RECORD  lpBuffer,
      DWORD               nLength,
      LPDWORD             lpNumberOfEventsRead
    )'
  ) or die "Import ReadConsoleInput: $EXTENDED_OS_ERROR";
}

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 EXPORTS

Nothing per default, but can export the following per request:

  KEY_EVENT
  MOUSE_EVENT
  WINDOW_BUFFER_SIZE_EVENT

=cut

use Exporter qw(import);

our @EXPORT_OK = qw(
  KEY_EVENT
  MOUSE_EVENT
  WINDOW_BUFFER_SIZE_EVENT
);

BEGIN {
  my $wincon = Class::MOP::Package->initialize('Win32::Console');

  # Add Windows Console API Function to Win32::Console
  $wincon->add_package_symbol('&_GetCurrentConsoleFont'
                            , \&_GetCurrentConsoleFont);

  # Update Windows Console API Function
  $wincon->add_package_symbol('&_ReadConsoleInput'
                            , \&_ReadConsoleInput);

  # Update patched Win32::Console constructor/destructor
  $wincon->add_package_symbol('&new'
                            , \&new);
  $wincon->add_package_symbol('&DESTROY'
                            , \&DESTROY);

  # Update patched Win32::Console methods
  $wincon->add_package_symbol('&Write'
                            , \&Write);
  $wincon->add_package_symbol('&Input'
                            , \&Input);

  # Add new Win32::Console methods
  $wincon->add_package_symbol('&Close'
                            , \&Close);
  $wincon->add_package_symbol('&isConsole'
                            , \&isConsole);
}

# ------------------------------------------------------------------------
# Constants --------------------------------------------------------------
# ------------------------------------------------------------------------

  use constant {
    KEY_EVENT                => 0x0001,
    MOUSE_EVENT              => 0x0002,
    WINDOW_BUFFER_SIZE_EVENT => 0x0004,
  };

# ------------------------------------------------------------------------
# Subroutines ------------------------------------------------------------
# ------------------------------------------------------------------------

  # Retrieves information about the current console font
  #===========================
  sub _GetCurrentConsoleFont {
  #===========================
    my ($handle, $maxWindow) = @_;
    return !!0
        if !( is_Int($handle) && is_Bool($maxWindow) );

    my $fontInfo = Win32::API::Struct->new('CONSOLE_FONT_INFO');
      $fontInfo->{nFont}
    = $fontInfo->{dwFontSize}->{X}
    = $fontInfo->{dwFontSize}->{Y}
    = 0;
    return GetCurrentConsoleFont( $handle, $maxWindow, $fontInfo )
      ?
    (
      $fontInfo->{nFont},
      $fontInfo->{dwFontSize}->{X},
      $fontInfo->{dwFontSize}->{Y},
    )
      :
    ()
  }

  # _ReadConsoleInput with Unicode and WindowBufferSizeEvent support
  #======================
  sub _ReadConsoleInput {
  #======================
    my ($handle) = @_;
    return !!0 unless is_Int($handle);
    
    my ($event_type) = do {
      my $ir = Win32::API::Struct->new('KEY_EVENT_RECORD');
      my $ok
      = $ir->{EventType}
      = $ir->{bKeyDown}
      = $ir->{wRepeatCount}
      = $ir->{wVirtualKeyCode}
      = $ir->{wVirtualScanCode}
      = $ir->{UnicodeChar}
      = $ir->{dwControlKeyState}
      = 0;
      PeekConsoleInput( $handle, $ir, 1, $ok ) && $ok
        ?
      ( $ir->{EventType} )
        :
      ()
        ;
    };
    $event_type //= 0;

    SWITCH: for ($event_type) {

      $_ == KEY_EVENT and do {
        my @event = do {
          # Win32::Console::Input() may not support Unicode, so the native
          # Windows API 'ReadConsoleInputW' call is used instead.
          my $ir = Win32::API::Struct->new('KEY_EVENT_RECORD');
          my $ok
          = $ir->{EventType}
          = $ir->{bKeyDown}
          = $ir->{wRepeatCount}
          = $ir->{wVirtualKeyCode}
          = $ir->{wVirtualScanCode}
          = $ir->{UnicodeChar}
          = $ir->{dwControlKeyState}
          = 0;
          ReadConsoleInputW( $handle, $ir, 1, $ok ) && $ok
            ?
          ( $ir->{EventType}
          , $ir->{bKeyDown}
          , $ir->{wRepeatCount}
          , $ir->{wVirtualKeyCode}
          , $ir->{wVirtualScanCode}
          , $ir->{UnicodeChar}
          , $ir->{dwControlKeyState}
          )
            :
          ()
            ;
        };
        return  @event
              ? @event
              : undef
              ;
      };

      $_ == MOUSE_EVENT and do {
        return
          Win32::Console::_ReadConsoleInput($handle);
      };
    
      # Win32::Console::Input() does not support 'WindowBufferSizeEvent'
      $_ = WINDOW_BUFFER_SIZE_EVENT and do {
        my ( $size_x, $size_y );
        # Calling stdout is unsafe, so it is embedded in eval
        eval {
          ( $size_x, $size_y )
            = TurboVision::Drivers::Win32::StdioCtl->instance()->out()->Size();
        } or return undef;

        # Consume event from the Windows event queue
        Win32::Console::_ReadConsoleInput($handle);

        return ( $event_type, $size_x, $size_y );
      };

      DEFAULT: {
        return
          Win32::Console::_ReadConsoleInput($handle);
      };
    }
  }

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

  ------------------------------------------------------------------------
  Fix Module Win32::Console version 0.10
  ------------------------------------------------------------------------
  
  1. Since you didn't open those handles (that's not what GetStdHandle does),
     you don't need to close them.
  2. The parameter 'dwShareMode' can be 0 (zero), indicating that the buffer
     cannot be shared
  3. Note that standard I/O handles should be INVALID_HANDLE_VALUE instead
     of 0 (NULL).
  4. Close shortcut is not implemented.
  5. Writing 0 bytes causes the cursor to become invisible for a short time
     in old versions of the Windows console.
  
  https://rt.cpan.org/Public/Bug/Display.html?id=33513
  https://docs.microsoft.com/en-us/windows/console/createconsolescreenbuffer
  https://stackoverflow.com/a/14730120/12342329
  https://rt.cpan.org/Public/Bug/Display.html?id=64676
  
  ------------------------------------------------------------------------

=cut
 
  # ------------------------------------------------------------------------
  # Constructors -----------------------------------------------------------
  # ------------------------------------------------------------------------

  # fix 1..3 - see below
  #========
  sub new {
  #========
    my ($class, $param1, $param2) = @_;
    my $self = { '_patched' => 1 };

    if ( defined( $param1 )
    && (
             $param1 == Win32::Console::constant("STD_INPUT_HANDLE",  0)
          || $param1 == Win32::Console::constant("STD_OUTPUT_HANDLE", 0)
          || $param1 == Win32::Console::constant("STD_ERROR_HANDLE",  0)
        )
    ) {
      $self->{'handle'} = Win32::Console::_GetStdHandle( $param1 );
      # fix 1 - Close only non standard handle
      $self->{'handle_is_std'} = 1;
    }
    else {
      if ( !$param1 ) {
        $param1 = Win32::Console::constant("GENERIC_READ", 0)
                | Win32::Console::constant("GENERIC_WRITE", 0)
                ;
      }
      # fix 2 - The value 0 (zero) is also a permitted value
      if ( !defined( $param2 ) ) {
        $param2 = Win32::Console::constant("FILE_SHARE_READ", 0)
                | Win32::Console::constant("FILE_SHARE_WRITE", 0)
                ;
      }
      $self->{'handle'} = Win32::Console::_CreateConsoleScreenBuffer(
          $param1
        , $param2
        , Win32::Console::constant("CONSOLE_TEXTMODE_BUFFER", 0)
      );
    }
    # fix 3 - If handle is undefined, 0 or -1 then the handle is invalid.
    if (
         $self->{'handle'}
      && $self->{'handle'} != Win32API::File::INVALID_HANDLE_VALUE
    ) {
      bless $self, $class;
      return $self;
    }
    return;
  }

  # ------------------------------------------------------------------------
  # Destructors ------------------------------------------------------------
  # ------------------------------------------------------------------------

  # fix 1 - Close only non standard handle
  #============
  sub DESTROY {
  #============
    my ($self) = @_;
    $self->Close() unless $self->{'handle_is_std'};
    return;
  }

  # ------------------------------------------------------------------------
  # Win32::Console ---------------------------------------------------------
  # ------------------------------------------------------------------------

  # fix 4 - Implement Close
  #==========
  sub Close {
  #==========
    my ($self) = @_;
    return undef unless ref($self);
    return Win32::Console::_CloseHandle($self->{'handle'});
  }

  # Unicode and WindowBufferSizeEvent support
  #==========
  sub Input {
  #==========
    my($self) = @_;
    return undef unless ref($self);
    return _ReadConsoleInput($self->{'handle'});
  }

  # fix 5 - Writing 0 bytes
  #==========
  sub Write {
  #==========
    my ($self, $string) = @_;
    return undef unless ref($self);
    return undef unless length($string);
    return Win32::Console::_WriteConsole($self->{'handle'}, $string);
  }

  # Ok, this is an extension
  #==============
  sub isConsole {
  #==============
    my ($self) = @_;
    return undef unless ref($self);
    return !!$self->Mode();
  }

1;

__END__

=head1 COPYRIGHT AND LICENCE

 This file is part of the port of the Turbo Vision library.

 Interface Copyright (c) 1992 Borland International

 The library files are licensed under modified LPGL.

 The creation of subclasses of this LGPL-licensed class is considered to be
 using an interface of a library, in analogy to a function call of a library.
 It is not considered a modification of the original class. Therefore,
 subclasses created in this way are not subject to the obligations that an LGPL
 imposes on licensees.

=head1 AUTHORS
 
=over

=item *

2023 by J. Schneider L<https://github.com/brickpool/>

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

L<Console Functions|https://learn.microsoft.com/en-us/windows/console/console-functions>, 
L<stdioctl.h|https://github.com/magiblot/tvision/blob/ad2a2e7ce846c3d9a7746c7ed278c00c8c1d6583/include/tvision/internal/stdioctl.h>, 
L<stdioctl.cpp|https://github.com/magiblot/tvision/blob/279648f8a67af14ec38725266037c39fb9add9b3/source/platform/stdioctl.cpp>
