=pod

=head1 NAME

TurboVision::Drivers::Win32::StdioCtl - Implementation of a STD ioctl.

=cut

package TurboVision::Drivers::Win32::StdioCtl;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

use Function::Parameters {
  factory => {
    defaults    => 'classmethod_strict',
    shift       => '$class',
    name        => 'required',
  },
},
qw(
  method
);

use Moose;
use MooseX::Types::Moose qw( :all );
use MooseX::HasDefaults::RO;
use namespace::autoclean;

# version '...'
our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;

# authority '...'
our $AUTHORITY = 'github:magiblot';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use English qw( -no_match_vars );
use List::Util qw( min max );
use Try::Tiny;

use TurboVision::Const qw(
  :bool
  :platform
);
use TurboVision::Drivers::Types qw( StdioCtl );

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
  Win32::API::More->Import(kernelDll, 
    'BOOL GetCurrentConsoleFont(
      HANDLE              hConsoleOutput,
      BOOL                bMaximumWindow,
      LPCONSOLE_FONT_INFO lpConsoleCurrentFont
    )'
  ) or die "Import GetCurrentConsoleFont: $EXTENDED_OS_ERROR";
}

# ------------------------------------------------------------------------
# Fix Module Win32::Console version 0.10
# ------------------------------------------------------------------------
#
# 1. Since you didn't open those handles (that's not what GetStdHandle does),
#    you don't need to close them.
# 2. The parameter 'dwShareMode' can be 0 (zero), indicating that the buffer
#    cannot be shared
# 3. Note that standard I/O handles should be INVALID_HANDLE_VALUE instead
#    of 0 (NULL).
# 4. Close shortcut is not implemented.
# 5. Writing 0 bytes causes the cursor to become invisible for a short time
#    in old versions of the Windows console.
#
# https://rt.cpan.org/Public/Bug/Display.html?id=33513
# https://docs.microsoft.com/en-us/windows/console/createconsolescreenbuffer
# https://stackoverflow.com/a/14730120/12342329
# https://rt.cpan.org/Public/Bug/Display.html?id=64676
#
# ------------------------------------------------------------------------

package Win32::Console::Fix {

  use parent 'Win32::Console';

  use English qw( -no_match_vars );
  use Win32::API;

  BEGIN {
    use constant kernelDll => 'kernel32';
  
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

  use constant {
    KEY_EVENT                => 0x0001,
    MOUSE_EVENT              => 0x0002,
    WINDOW_BUFFER_SIZE_EVENT => 0x0004,
  };

  # fix 1..3 - see below
  #========
  sub new {
  #========
    require Win32API::File;

    my ($class, $param1, $param2) = @_;
    my $self = {};

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

  # fix 1 - Close only non standard handle
  #============
  sub DESTROY {
  #============
    my ($self) = @_;
    $self->Close() unless $self->{'handle_is_std'};
    return;
  }

  # fix 4 - Implement Close
  #==========
  sub Close {
  #==========
    my ($self) = @_;
    return undef unless ref($self);
    return Win32::Console::_CloseHandle($self->{'handle'});
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

  # Unicode and WindowBufferSizeEvent support
  #==============
  sub Input {
  #==============
    my ($self) = @_;
    return undef unless ref($self);
    
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
      PeekConsoleInput( $self->{'handle'}, $ir, 1, $ok ) && $ok
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
          ReadConsoleInputW( $self->{'handle'}, $ir, 1, $ok ) && $ok
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
          Win32::Console::_ReadConsoleInput($self->{'handle'});
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
        Win32::Console::_ReadConsoleInput($self->{'handle'});

        return ( $event_type, $size_x, $size_y );
      };

      DEFAULT: {
        return
          Win32::Console::_ReadConsoleInput($self->{'handle'});
      };
    }
  }

}

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

I<StdioCtl> (an abbreviation of Standard input/output control) is a system call
for device-specific input/output operations and other operations which cannot be
expressed by regular system calls. 

I<StdioCtl> is singleton a class that has only one instance in an application.
The module I<MooseX::Singleton> uses metaclass roles to do the magic.

=head2 Class

public class C<< StdioCtl >>

Turbo Vision Hierarchy

  Moose::Object
    StdioCtl

=cut

package TurboVision::Drivers::Win32::StdioCtl {
  
  # ------------------------------------------------------------------------
  # Attributes -------------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Attributes

=over

=item public C<< Object in >>

Console input object (e.g I<< Win32::Console->new(STD_INPUT_HANDLE) >>).

=cut

  has 'in' => (
    isa       => Object,
    writer    => '_input',
    predicate => '_has_input',
    init_arg  => undef,
  );

=item public C<< Object out >>

Console active output object.

=cut

  has 'out' => (
    isa       => Object,
    writer    => '_output',
    predicate => '_has_output',
    init_arg  => undef,
  );
  
=begin comment

=item private C<< Object _startup >>

Console startup output object.

=end comment

=cut

  has '_startup' => (
    is        => 'rw',
    isa       => Object,
    predicate => '_has_startup',
  );

=begin comment

=item private C<< Bool _owns_console >>

Console startup output object.

=end comment

=cut

  has '_owns_console' => (
    is        => 'rw',
    isa       => Bool,
    default   => _FALSE,
  );

=back

=cut

  # ------------------------------------------------------------------------
  # Constructors -----------------------------------------------------------
  # ------------------------------------------------------------------------

  use constant FACTORY => StdioCtl;

=head2 Constructors

=over

=item public C<< StdioCtl->instance() >>

This constructor instantiates an object instance if none exists, otherwise it
returns an existing instance.

It is used to initialize the default I/O console.

=cut

  my %_instances;
  factory instance() {
    if ( !defined $_instances{$class} ) {
      $_instances{$class} = $class->new();
    }
    return $_instances{$class};
  }

=begin comment

=item private C<< BUILD(@) >>

This internal method is automatically called when the object is created via
I<new> or I<init>. It initializes the console.

=end comment

=cut

  method BUILD(@) {

    #
    # The console can be accessed in two ways: through GetStdHandle() or through
    # CreateFile(). GetStdHandle() will be unable to return a console handle if
    # standard handles have been redirected.
    # 
    # Additionally, we want to spawn a new console when none is visible to the
    # user. This might happen under two circumstances:
    # 
    # 1. The console crashed. This is easy to detect because all console
    #    operations fail on the console handles.
    # 2. The console exists somehow but cannot be made visible, not even by
    #    doing GetConsoleWindow() and then ShowWindow(SW_SHOW). This is what
    #    happens under Git Bash without pseudoconsole support. In this case,
    #    none of the standard handles is a console, yet the handles returned by
    #    CreateFile() still work.
    # 
    # So, in order to find out if a console needs to be allocated, we check
    # whether at least of the standard handles is a console. If none of them is,
    # we allocate a new console. Yes, this will always spawn a console if all
    # three standard handles are redirected, but this is not a common use case.
    # 
    # Then comes the question of whether to access the console through
    # GetStdHandle() or through CreateFile(). CreateFile() has the advantage of
    # not being affected by standard handle redirection. However, I have found
    # that some terminal emulators (i.e. ConEmu) behave unexpectedly when using
    # screen buffers opened with CreateFile(). So we will use the standard 
    # handles whenever possible.
    # 
    # It is worth mentioning that the handles returned by CreateFile() have to
    # be closed, but the ones returned by GetStdHandle() must not. So we have to
    # remember this information for each console handle.
    # 
    # We also need to remember whether we allocated a console or not, so that we
    # can free it when tearing down. If we don't, weird things may happen.
    # 

    my $console;
    my $have_console = _FALSE;

    $console = Win32::Console::Fix->new( STD_INPUT_HANDLE );
    if ( $console && $console->isConsole() ) {
      $have_console = _TRUE;
      if ( !$self->_has_input ) {
        $self->_input( $console );
      }
    }

    $console = Win32::Console::Fix->new( STD_OUTPUT_HANDLE );
    if ( $console && $console->isConsole()  ) {
      $have_console = _TRUE;
      if ( !$self->_has_startup ) {
        $self->_startup( $console );
      }
    }

    $console = Win32::Console::Fix->new( STD_ERROR_HANDLE );
    if ( $console && $console->isConsole() ) {
      $have_console = _TRUE;
      if ( !$self->_has_startup ) {
        $self->_startup( $console );
      }
    }

    if ( !$have_console ) {
      Win32::Console::Free();
      Win32::Console::Alloc();
      $self->_owns_console( _TRUE );
    }

    if ( !$self->_has_input ) {
      # Create a new generic object
      $console = Win32::Console::Fix->new();              
      if ( $console && $console->isConsole() ) {
        # If object is a valid console, close the old handle
        $console->Close();
        # Assign a handle created by CreateFile() to the object
        $console->{handle} = Win32API::File::createFile(
          'CONIN$',
          {
            Access => GENERIC_READ | GENERIC_WRITE,
            Share  => FILE_SHARE_READ,
            Create => Win32API::File::OPEN_EXISTING,
          }
        );
        $self->_input( $console );
      }
    }

    if ( !$self->_has_startup ) {
      $console = Win32::Console::Fix->new();
      if ( $console && $console->isConsole() ) {
        $console->Close();
        $console->{handle} = Win32API::File::createFile(
          'CONOUT$',
          {
            Access => GENERIC_READ | GENERIC_WRITE,
            Share  => FILE_SHARE_WRITE,
            Create => Win32API::File::OPEN_EXISTING,
          }
        );
        $self->_startup( $console );
      }
    }

    $console = Win32::Console::Fix->new( GENERIC_READ | GENERIC_WRITE, 0 );
    if ( $console && $console->isConsole() ) {
      $self->_output( $console );
      if ( my @info = $self->_startup->Info() ) {
        my ($left, $top, $right, $bottom) = @info[5..8];
        # Force the screen buffer size to match the window size.
        # The Console API guarantees this, but some implementations
        # are not compliant (e.g. Wine).
        my $size_x = $right - $left + 1;
        my $size_y = $bottom - $top + 1;
        $self->out->Size( $size_x, $size_y );
      }
      $self->out->Display();
    }
   
    unless ( $self->_has_input || $self->_has_startup || $self->_has_output ) {
      confess "Error: cannot get a console.\n";
    }

    return;
  }
  
=back

=cut

  # ------------------------------------------------------------------------
  # Destructors ------------------------------------------------------------
  # ------------------------------------------------------------------------

=begin comment

=head2 Destructors

=over

=item public C<< DEMOLISH(@) >>

I<DEMOLISH> restore the startup output console.

Under Windows, I<FreeConsole> is also called to stop supporting the Windows
console.

=end comment

=cut

  method DEMOLISH(@) {

    #
    # We have a problem with DEMOLISH for this singleton class. 
    # Therefore, I have decided to suppress the following message:
    # "(in cleanup) at <..>/Moose/Object.pm line <..> during global destruction"
    #
    eval {
      if ( $self->_has_startup ) {
        $self->_startup->Display();
      }
      if ( $self->_owns_console ) {
        Win32::Console::Free();
      }
    };

    return;
  }

=begin comment

=back

=end comment

=cut

  # ------------------------------------------------------------------------
  # StdioCtl ---------------------------------------------------------------
  # ------------------------------------------------------------------------
  
=head2 Methods

=over

=item public C<< Dict[x => Int, y => Int] get_size() >>

Gets the console buffer size.

=cut

  method get_size() {

    if ( my @info = $self->out->Info() ) {
      my ( $left, $top, $right, $bottom ) = @info[5..8];
      return {
        x => max( $right - $left + 1, 0 ),
        y => max( $bottom - $top + 1, 0 ),
      };
    }

    return {
      x => 0,
      y => 0,
    };
  }

=item public C<< Dict[x => Int, y => Int] get_font_size() >>

Gets the font size.

=cut

  method get_font_size() {

    my $fontInfo = Win32::API::Struct->new('CONSOLE_FONT_INFO');
    $fontInfo->{nFont} = 0;
    $fontInfo->{dwFontSize}->{X} = 0;
    $fontInfo->{dwFontSize}->{Y} = 0;
    if ( GetCurrentConsoleFont( $self->out->{handle}, _FALSE, $fontInfo ) ) {
      return {
        x => $fontInfo->{dwFontSize}->{X},
        y => $fontInfo->{dwFontSize}->{Y},
      };
    }

    return {
      x => 0,
      y => 0,
    };
  }

=back

=head2 Inheritance

Methods inherited from role C<MooseX::Singleton>

  instance, initialize, _clear_instance, new

Methods inherited from class C<Object>

  BUILDARGS, does, DOES, dump, DESTROY

=cut

}

1;

__END__

=head1 COPYRIGHT AND LICENCE

 This file is part of the port of the Turbo Vision library.

 Copyright (c) 2019-2021 by magiblot

 This library content was taken from the framework
 "A modern port of Turbo Vision 2.0", which is licensed under MIT licence.

=head1 AUTHORS
 
=over

=item *

2019-2021 by magiblot E<lt>magiblot@hotmail.comE<gt>

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

I<Moose::Object>, 
L<stdioctl.h|https://github.com/magiblot/tvision/blob/ad2a2e7ce846c3d9a7746c7ed278c00c8c1d6583/include/tvision/internal/stdioctl.h>, 
L<stdioctl.cpp|https://github.com/magiblot/tvision/blob/279648f8a67af14ec38725266037c39fb9add9b3/source/platform/stdioctl.cpp>
