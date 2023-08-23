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

use constant::boolean;
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
use MooseX::AttributeShortcuts;
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

use Carp;
use English qw( -no_match_vars );
use List::Util qw( max );
use Try::Tiny;
use Win32::Console;
use Win32API::File;

use TurboVision::Const qw( :platform );
use TurboVision::Drivers::Types qw( StdioCtl );
use TurboVision::Drivers::Win32::Console;

# ------------------------------------------------------------------------
# Class Defnition --------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

I<StdioCtl> (an abbreviation of Standard input/output control) is a system call
for device-specific input/output operations and other operations which cannot be
expressed by regular system calls. 

I<StdioCtl> is singleton a class that has only one instance in an application.
The module is similar to the functionalities of L<MooseX::Singleton>.

=head2 Class

public class I<< StdioCtl >>

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

=item I<in>

  field in (
    is        => 'ro',
    type      => Object,
    writer    => '_input',
    predicate => '_has_input',
  );

Console input object (e.g I<< Win32::Console->new(STD_INPUT_HANDLE) >>).

=cut

  has 'in' => (
    isa       => Object,
    writer    => '_input',
    predicate => '_has_input',
    init_arg  => undef,
  );

=item I<out>

  field out (
    is        => 'ro',
    type      => Object,
    writer    => '_output',
    predicate => '_has_output',
  );

Console active output object.

=cut

  has 'out' => (
    isa       => Object,
    writer    => '_output',
    predicate => '_has_output',
    init_arg  => undef,
  );
  
=begin comment

=item I<_startup>

  has _startup ( is => rw, type => Object, predicate => 1 );

Console startup output object.

=end comment

=cut

  has '_startup' => (
    is        => 'rw',
    isa       => Object,
    predicate => 1,
  );

=begin comment

=item I<_owns_console>

  has _owns_console ( is => rw, type => Bool ) = !! 0;

Console startup output object.

=end comment

=cut

  has '_owns_console' => (
    is      => 'rw',
    isa     => Bool,
    default => FALSE,
  );

=back

=cut

  # ------------------------------------------------------------------------
  # Constructors -----------------------------------------------------------
  # ------------------------------------------------------------------------

  use constant FACTORY => StdioCtl;

=head2 Constructors

=over

=item I<instance>

  factory $class->instance() : StdioCtl

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

=item I<BUILD>

  method BUILD()

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
    my $have_console = FALSE;

    $console = Win32::Console->new( STD_INPUT_HANDLE );
    if ( $console && $console->is_valid() ) {
      $have_console = TRUE;
      if ( !$self->_has_input ) {
        $self->_input( $console );
      }
    }

    $console = Win32::Console->new( STD_OUTPUT_HANDLE );
    if ( $console && $console->is_valid()  ) {
      $have_console = TRUE;
      if ( !$self->_has_startup ) {
        $self->_startup( $console );
      }
    }

    $console = Win32::Console->new( STD_ERROR_HANDLE );
    if ( $console && $console->is_valid() ) {
      $have_console = TRUE;
      if ( !$self->_has_startup ) {
        $self->_startup( $console );
      }
    }

    if ( !$have_console ) {
      Win32::Console::Free();
      Win32::Console::Alloc();
      $self->_owns_console( TRUE );
    }

    if ( !$self->_has_input ) {
      # Create a new generic object
      $console = Win32::Console->new();              
      if ( $console && $console->is_valid() ) {
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
      $console = Win32::Console->new();
      if ( $console && $console->is_valid() ) {
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

    $console = Win32::Console->new( GENERIC_READ | GENERIC_WRITE, 0 );
    if ( $console && $console->is_valid() ) {
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

=item I<DEMOLISH>

  method DEMOLISH()

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

=item I<get_size>

  method get_size() : Dict[x => Int, y => Int] 

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

=item I<get_font_size>

  method get_font_size() : Dict[x => Int, y => Int] 

Gets the font size.

=cut

  method get_font_size() {

    my $fontInfo = Win32::API::Struct->new('CONSOLE_FONT_INFO');
    $fontInfo->{nFont} = 0;
    $fontInfo->{dwFontSize}->{X} = 0;
    $fontInfo->{dwFontSize}->{Y} = 0;
    if ( Win32::Console::_GetCurrentConsoleFont( $self->out->{handle}, FALSE, $fontInfo ) ) {
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

Methods inherited from class L<Moose::Object>

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

L<Moose::Object>, 
L<stdioctl.h|https://github.com/magiblot/tvision/blob/ad2a2e7ce846c3d9a7746c7ed278c00c8c1d6583/include/tvision/internal/stdioctl.h>, 
L<stdioctl.cpp|https://github.com/magiblot/tvision/blob/279648f8a67af14ec38725266037c39fb9add9b3/source/platform/stdioctl.cpp>
