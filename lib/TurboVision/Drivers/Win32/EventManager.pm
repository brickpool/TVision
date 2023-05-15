=pod

=head1 NAME

TurboVision::Drivers::Win32::EventManager - Event Manager implementation

=cut

package TurboVision::Drivers::Win32::EventManager;

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
our $AUTHORITY = 'github:magiblot';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use Data::Alias qw( alias );
use Devel::StrictMode;
use Encode qw( decode );
use PerlX::Assert;
use POSIX qw(
  setlocale
  LC_ALL
);

use TurboVision::Const qw( :bool );
use TurboVision::Objects::Types qw( TPoint );
use TurboVision::Drivers::Const qw(
  :evXXXX
  :kbXXXX
  :mbXXXX
  :private
);
use TurboVision::Drivers::Event;
use TurboVision::Drivers::Types qw(
  TEvent
  StdioCtl
);
use TurboVision::Drivers::Win32::StdioCtl;

use Win32::Console;

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 EXPORTS

Nothing per default, but can export the following per request:

  :all
  
    :events
      init_events
      done_events

    :private
      $_auto_delay
      $_auto_ticks
      $_down_buttons
      $_down_ticks
      $_down_where
      @_event_queue
      $_last_buttons
      $_last_double
      $_last_where
      $_shift_state
      $_ticks

      _update_event_queue

=cut

use Exporter qw(import);

our @EXPORT_OK = qw(
);

our %EXPORT_TAGS = (

  events => [qw(
    init_events
    done_events
  )],

  private => [qw(
    $_auto_delay
    $_auto_ticks
    $_down_buttons
    $_down_ticks
    $_down_where
    @_event_queue
    $_last_buttons
    $_last_double
    $_last_where
    $_shift_state
    $_ticks

    _set_shift_state
    _update_event_queue
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

=begin comment

=head2 Constants

=over

=item private const C<< Ref _ALT_CVT >>

=item private const C<< Ref _CTRL_CVT >>

=item private const C<< Ref _NORMAL_CVT >>

=item private const C<< Ref _SHIFT_CVT >>

Scancode mapping tables.

=end comment

=cut

  use constant _ALT_CVT => sub {+[
         0,      0, 0x7800, 0x7900, 0x7a00, 0x7b00, 0x7c00, 0x7d00,
    0x7e00, 0x7f00, 0x8000, 0x8100, 0x8200, 0x8300, 0x0800,      0,
    0x1000, 0x1100, 0x1200, 0x1300, 0x1400, 0x1500, 0x1600, 0x1700,
    0x1800, 0x1900,      0,      0,      0,      0, 0x1e00, 0x1f00,
    0x2000, 0x2100, 0x2200, 0x2300, 0x2400, 0x2500, 0x2600,      0,
         0,      0,      0,      0, 0x2c00, 0x2d00, 0x2e00, 0x2f00,
    0x3000, 0x3100, 0x3200,      0,      0,      0,      0,      0,
         0, 0x0200,      0, 0x6800, 0x6900, 0x6a00, 0x6b00, 0x6c00,
    0x6d00, 0x6e00, 0x6f00, 0x7000, 0x7100,      0,      0, 0x9700,
    0x9800, 0x9900,      0, 0x9b00,      0, 0x9d00,      0, 0x9f00,
    0xa000, 0xa100, 0xa200, 0xa300,      0,      0,      0, 0x8b00,
    0x8c00
  ]->[ +shift ]};

  use constant _CTRL_CVT => sub {+[
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0,      0,
    0x0011, 0x0017, 0x0005, 0x0012, 0x0014, 0x0019, 0x0015, 0x0009,
    0x000f, 0x0010,      0,      0,      0,      0, 0x0001, 0x0013,
    0x0004, 0x0006, 0x0007, 0x0008, 0x000a, 0x000b, 0x000c,      0,
         0,      0,      0,      0, 0x001a, 0x0018, 0x0003, 0x0016,
    0x0002, 0x000e, 0x000d,      0,      0,      0,      0,      0,
         0,      0,      0, 0x5e00, 0x5f00, 0x6000, 0x6100, 0x6200,
    0x6300, 0x6400, 0x6500, 0x6600, 0x6700,      0,      0, 0x7700,
    0x8d00, 0x8400,      0, 0x7300,      0, 0x7400,      0, 0x7500,
    0x9100, 0x7600, 0x0400, 0x0600,      0,      0,      0, 0x8900,
    0x8a00
  ]->[ +shift ]};

  use constant _NORMAL_CVT => sub {+[
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0, 0x8500,
    0x8600
  ]->[ +shift ]};

  use constant _SHIFT_CVT => sub {+[
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0, 0x0f00,
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0,      0, 0x5400, 0x5500, 0x5600, 0x5700, 0x5800,
    0x5900, 0x5a00, 0x5b00, 0x5c00, 0x5d00,      0,      0,      0,
         0,      0,      0,      0,      0,      0,      0,      0,
         0,      0, 0x0500, 0x0700,      0,      0,      0, 0x8700,
    0x8800
  ]->[ +shift ]};

=begin comment

=item private const C<< Int _CM_SCREEN_CHANGED >>

Defines a constant for changing the size of the console screen buffer

=end comment

=cut

  use constant _CM_SCREEN_CHANGED => 57;

=begin comment

=item private const C<< Int _CP_UTF8 >>

Windows code page value for UTF-8.

=end comment

=cut

  use constant _CP_UTF8 => 65001;

=begin comment

=item private const C<< Int _CTRL_Z >>

Ctrl-Z is the last Ctrl+key.

=end comment

=cut

  use constant _CTRL_Z  => 0x1a;

=begin comment

=item private const C<< Int _ENABLE_INSERT_MODE >>

=item private const C<< Int _ENABLE_QUICK_EDIT_MODE >>

=item private const C<< Int _ENABLE_EXTENDED_FLAGS >>

Addional I<Win32::Console> modes.

See also: I<SetConsoleMode>

=end comment

=cut

  use constant {
    _ENABLE_INSERT_MODE     => 0x0020,
    _ENABLE_QUICK_EDIT_MODE => 0x0040,
    _ENABLE_EXTENDED_FLAGS  => 0x0080,
  };

=begin comment

=item private const C<< Int _DOUBLE_CLICK >>

=item private const C<< Int _MOUSE_WHEELED >>

The second click (button press) of a double-click occurred. The first click is
returned as a regular button-press event.

The vertical mouse wheel was moved.

=end comment

=cut

  use constant {
    _DOUBLE_CLICK  => 0x0002,
    _MOUSE_WHEELED => 0x0004,
  };

=begin comment

=item private const C<< Int _KEY_EVENT >>

=item private const C<< Int _MOUSE_EVENT >>

=item private const C<< Int _WINDOW_BUFFER_SIZE_EVENT >>

The event constant for identifying an I<_KEY_EVENT_RECORD> structure
(information about a keyboard event), an I<_MOUSE_EVENT_RECORD> structure
(information about a mouse movement or mouse button), or an
I<_WINDOW_BUFFER_SIZE_EVENT> structure (information about the new size of the
console screen buffer).

=end comment

=cut

  use constant {
    _KEY_EVENT                => 0x0001,
    _MOUSE_EVENT              => 0x0002,
    _WINDOW_BUFFER_SIZE_EVENT => 0x0004,
  };

=begin comment

=item private const C<< Int _VK_SHIFT >>

=item private const C<< Int _VK_CONTROL >>

=item private const C<< Int _VK_MENU >>

=item private const C<< Int _VK_INSERT >>

Virtual-Key Codes for Shift, Ctrl, Alt and Insert.

=end comment

=cut

  use constant {
    _VK_SHIFT   => 0x10,
    _VK_CONTROL => 0x11,
    _VK_MENU    => 0x12,
    _VK_INSERT  => 0x2d,
  };

=begin comment

=back

=end comment

=cut

# ------------------------------------------------------------------------
# Variables --------------------------------------------------------------
# ------------------------------------------------------------------------
  
=head2 Variables

=over

=item private readonly C<< Int $_auto_delay >>

Event manager variable for I<EV_MOUSE_AUTO> delay time counter.

=cut

  our $_auto_delay = 0;

=item private readonly C<< Int $_auto_ticks >>

Event manager variable for held mouse button tick counter.

=cut

  our $_auto_ticks = 0;

=item private readonly C<< Int $_down_buttons >>

Event manager variable for the current state of the mouse buttons.

=cut

  our $_down_buttons = 0;

=item private readonly C<< Int $_down_ticks >>

Event manager variable for down mouse button tick counter.

=cut

  our $_down_ticks = 0;

=item private readonly C<< TPoint $_down_where >>

Event manager variable for the current state of the mouse position when the
mouse button is pressed.

=cut

  our $_down_where = TPoint->new( x => 0, y => 0 );

=item private readonly C<< Array @_event_queue >>

Event manager queue for the I<TEvent> records.

=cut

  our @_event_queue = ();

=item private readonly C<< Int $_last_buttons >>

Event manager variable for the previous state of the mouse buttons.

=cut

  our $_last_buttons = 0;

=item private readonly C<< Bool $_last_double >>

Event manager variable for the previous state of double klick.

=cut

  our $_last_double = _FALSE;

=item private readonly C<< TPoint $_last_where >>

Event manager variable for the previous mouse position.

=cut

  our $_last_where = TPoint->new( x => 0, y => 0 );

=item private readonly C<< Int $_shift_state >>

Key shift state.

=cut

  our $_shift_state = KB_INS_STATE;
  INIT {
    eval {
      $_shift_state = StdioCtl->instance->in->Mode & _ENABLE_INSERT_MODE
                    ? KB_INS_STATE
                    : 0
                    ;
    }
    or
      warn $@;
  };

=item private readonly C<< Int $_ticks >>

This variable returns the number of timer ticks (1 second = 18.2 ticks), similar
to the direct memory access to the low memory address 0x40:0x6C.

Note: On non-Windows systems, the variable uses the elapsed time since the
program startup (not the system startup time).

=cut

  package System::GetDosTicks {
    use Time::HiRes qw( time );
    use English qw( -no_match_vars );
    use constant _WIN32 => $OSNAME =~ /win32|cygwin/i;
    use if _WIN32, 'Win32';

    sub TIESCALAR {
      my $class = shift;
      my $base_time = $BASETIME;
      if ( _WIN32 ) {{
        no strict;
        $base_time = time() - Win32::GetTickCount()/1000;
      }}
      my $self = \$base_time;
      return bless $self, $class;
    }
    
    sub FETCH {
      my $self = shift;
      my $base_time = $$self;
      return int( ( time() - $base_time ) * 18.2 );
    }

    1;
  }
  our $_ticks;
  tie $_ticks, qw( System::GetDosTicks );

=begin comment

=item local C<< Object $_io >>

STD ioctl object I<< StdioCtl->instance() >>

=end comment

=cut

  my $_io;
  INIT { $_io = StdioCtl->instance() }

=begin comment

=item local C<< Int $_save_cp_input >>

Saves the input codepage used by the startup console.

=end comment

=cut

  my $_save_cp_input = 850;

=begin comment

=item local C<< Int $_save_quick_mode >>

Saves the quick edit mode used by the mouse.

=end comment

=cut

  my $_save_quick_mode = _FALSE;

=back

=back

=cut

# ------------------------------------------------------------------------
# Subroutines ------------------------------------------------------------
# ------------------------------------------------------------------------

=head2 Subroutines

=item public C<< init_events() >>

This internal procedure initializes Turbo Vision's mouse event handler, and
initializes and displays the mouse, if installed.

<init_events> is automatically called by I<< TApplication->Init >>, and is
terminated by calling its corresponding I<done_events> procedure.

=cut

  func init_events() {
    my $CONSOLE = $_io->in();

    my $mode = $CONSOLE->Mode();
    $_save_quick_mode = !!(
      $mode & ( _ENABLE_EXTENDED_FLAGS | _ENABLE_QUICK_EDIT_MODE )
    );
    # Disable the Quick Edit mode, which inhibits the mouse.
    $mode |= _ENABLE_EXTENDED_FLAGS;
    $mode &= ~_ENABLE_QUICK_EDIT_MODE;
    $CONSOLE->Mode( $mode );

    require TurboVision::Drivers::Win32::Mouse;
    TurboVision::Drivers::Win32::Mouse::show_mouse();

    return;
  }

=item public C<< done_events() >>

This is a Turbo Vision internal routine that will not normally be used by your
applications.

I<done_events> disables the mouse event handler and hides the mouse.

=cut

  func done_events() {
    require TurboVision::Drivers::Win32::Mouse;
    TurboVision::Drivers::Win32::Mouse::hide_mouse();

    # Restore Quick Edit mode
    if ( $_save_quick_mode ) {
      my $CONSOLE = $_io->in();
      my $mode = $CONSOLE->Mode();
      $CONSOLE->Mode(
          $mode
        | _ENABLE_QUICK_EDIT_MODE
        | _ENABLE_EXTENDED_FLAGS
      );
    }

    return;
  }

=begin comment

=item private C<< Bool _set_key_event(HashRef $key_event, TEvent $event) >>

The routine translates the Windows I<KEY_EVENT_RECORD> to Turbo Vision's
I<TEvent>.

Returns true if successful.

=end comment

=cut

  func _set_key_event(HashRef $key_event, TEvent $event) {
    return _FALSE
        if !_set_unicode_event($key_event, $event);
    
    _set_shift_state($key_event, $_shift_state);

    $event->what( EV_KEY_DOWN );
    $event->scan_code( $key_event->{virtual_scan_code} );
    
    if ( $event->text ) {
      # Turbo Vision has all characters encoded in code page 437.
      # Windows console work with a byte-based character set (OEM code page).
      # The OEM code page is usually different from the code page 437.
      my $ch = _UTF8_TO_CP437->( ord $event->text );
      $event->char_code( $ch );

      if ( $key_event->{virtual_key_code} == _VK_MENU ) {
        # This is enabled when pasting certain characters, and it confuses
        # applications. Clear it.
        $event->scan_code( 0 );
      }
      
      if ( !$event->char_code || $event->key_code <= _CTRL_Z ) {
        # If the character cannot be represented in the current codepage,
        # or if it would accidentally trigger a Ctrl+Key combination,
        # make the whole key_code zero to avoid side effects.
        $event->key_code( KB_NO_KEY );
      }

    }
    else {
      $event->char_code( $key_event->{char} );

      if ( (
           $key_event->{virtual_key_code} == _VK_SHIFT
        || $key_event->{virtual_key_code} == _VK_CONTROL
        || $key_event->{virtual_key_code} == _VK_MENU
        )
          &&
        $key_event->{char} == 0
      ) {
        # Discard standalone Shift, Ctrl, Alt keys.
        $event->key_code( KB_NO_KEY );
      }
    }

    # Convert NT style virtual scan codes to PC BIOS codes.
    if (
      $key_event->{control_key_state} & (RIGHT_CTRL_PRESSED | LEFT_CTRL_PRESSED)
        &&                                              # Ctrl+Alt is AltGr
      $key_event->{control_key_state} & LEFT_ALT_PRESSED
        ||
      $key_event->{control_key_state} & RIGHT_ALT_PRESSED
    ) {                                                 
      # When AltGr+Key does not produce a character, a
      # key_code with unwanted effects may be read instead.
      if ( !$event->char_code ) {
        $event->key_code( KB_NO_KEY );
      }
    }
    elsif ( $key_event->{virtual_scan_code} < 89 ) {
      my $index = $key_event->{virtual_scan_code};

      if ( $_shift_state & KB_SHIFT
        && _SHIFT_CVT->($index)
      ) {
        $event->key_code( _SHIFT_CVT->($index) );
      }
      elsif ( $_shift_state & KB_CTRL_SHIFT
        && _CTRL_CVT->($index)
      ) {
        $event->key_code( _CTRL_CVT->($index) );
      }
      elsif ( $_shift_state & KB_ALT_SHIFT
        && _ALT_CVT->($index)
      ) {
        $event->key_code( _ALT_CVT->($index) );
      }
      elsif ( _NORMAL_CVT->($index) ) {
        $event->key_code( _NORMAL_CVT->($index) );
      }
    }

    return $event->key_code != KB_NO_KEY || $event->text;
  }

=begin comment

=item private C<< Bool _set_mouse_event(HashRef $mouse_event, TEvent $event) >>

The routine translates the Windows I<MOUSE_EVENT_RECORD> to Turbo Vision's
I<TEvent>.

Returns true if successful.

=end comment

=cut

  func _set_mouse_event(HashRef $mouse_event, TEvent $event) {
    # load mouse button delay counter
    my ( $_repeat_delay, $_double_delay ) = do {
      no warnings qw( once );
      (
        $TurboVision::Drivers::Win32::Mouse::repeat_delay,
        $TurboVision::Drivers::Win32::Mouse::double_delay
      );
    };

    # Get mouse button mask
    my $button_mask =
      $mouse_event->{button_state}
      & ( MB_LEFT_BUTTON | MB_RIGHT_BUTTON | MB_MIDDLE_BUTTON )
      ;

    # Rotation sense is represented by the sign of button_state's high word
    my $positive = not ( $mouse_event->{button_state} & 0x8000_0000 );
    if ( $mouse_event->{event_flags} & _MOUSE_WHEELED ) {
      $button_mask |= $positive ? MB_SCROLL_WHEEL_DOWN : MB_SCROLL_WHEEL_UP;
    }

    # Get current timer ticks
    my $timer_ticks = $_ticks;

    # Get mouse X and Y coordinate
    my $coordinate = TPoint->new(
      x => $mouse_event->{mouse_position}->{x},
      y => $mouse_event->{mouse_position}->{y},
    );

    my $double_click = _FALSE;
    if ( $button_mask != 0 && $_last_buttons == 0 ) {
      $double_click = not (
        $button_mask != $_down_buttons
          ||
        $coordinate != $_down_where
          ||
        $timer_ticks - $_down_ticks >= $_double_delay
      );
      $_down_buttons = $button_mask;
      $_down_where = $coordinate;
      $_down_ticks = $_auto_ticks = $timer_ticks;
      $_auto_delay = $_repeat_delay;
      $event->what( EV_MOUSE_DOWN );
    }
    elsif ( $button_mask == 0 && $_last_buttons != 0 ) {
      $event->what( EV_MOUSE_UP );
    }
    elsif ( $_last_buttons != $button_mask ) {
      if ( $button_mask > $_last_buttons ) {
        $event->what( EV_MOUSE_DOWN );
      }
      else {
        $event->what( EV_MOUSE_UP );
      }
    }
    elsif ( $coordinate != $_last_where ) {
      $event->what( EV_MOUSE_MOVE );
    }
    elsif ( $button_mask == 0 ) {
      return _FALSE;
    }
    elsif ( $timer_ticks - $_auto_ticks >= $_auto_delay ) {
      $_auto_ticks = $timer_ticks;
      $_auto_delay = 1;
      $event->what( EV_MOUSE_AUTO );
    }

    $_last_double = $double_click;
    $_last_buttons = $button_mask;
    $_last_where = $coordinate;

    $event->double ( $_last_double  );
    $event->buttons( $_last_buttons );
    $event->where  ( $_last_where   );

    _set_shift_state( $mouse_event, $_shift_state );

    return _TRUE;
  }

=begin comment

=item private C<< Bool _set_shift_state(HashRef $key_event, Int $shift_state) >>

This subroutine sets the state of the keyboard shift (comparable to the low
level call at memory position C<0x40:0x17>).

Returns true if successful.

See also: I<get_shift_state>

=end comment

=cut

  func _set_shift_state(HashRef $event, $) {
    alias my $shift_state = $_[-1];
    
    assert { is_Int $shift_state                };
    assert { exists $event->{event_type}        };
    assert { exists $event->{control_key_state} };
    
    $shift_state &= KB_INS_STATE;                       # clear all excl. insert

    $shift_state |= KB_SHIFT                            # set shift state
      if $event->{control_key_state}
        & SHIFT_PRESSED;

    $shift_state |= KB_CTRL_SHIFT                       # set ctrl state
      if $event->{control_key_state}
        & ( RIGHT_CTRL_PRESSED | LEFT_CTRL_PRESSED );

    $shift_state |= KB_ALT_SHIFT                        # set alt state
      if $event->{control_key_state}
        & LEFT_ALT_PRESSED;

    $shift_state |= KB_SCROLL_STATE                     # set scroll lock state
      if $event->{control_key_state}
        & SCROLLLOCK_ON;

    $shift_state |= KB_NUM_STATE                        # set num lock state
      if $event->{control_key_state}
        & NUMLOCK_ON;

    $shift_state |= KB_CAPS_STATE                       # set caps lock state
      if $event->{control_key_state}
        & CAPSLOCK_ON;

    $shift_state ^= KB_INS_STATE                        # toggle insert state
      if $event->{event_type} == _KEY_EVENT
      && $event->{virtual_key_code} == _VK_INSERT;

    return _TRUE;
  }

=begin comment

=item private C<< Bool _set_unicode_event(HashRef $key_event, TEvent $event) >>

Returns true unless the event contains a UTF-16 surrogate, in this case we need
the next event.

=end comment

=cut

  func _set_unicode_event(HashRef $key_event, TEvent $event) {
    state $surrogate = 0;
    
    my @utf16 = ( $key_event->{char}, 0 );
    $event->{text} = '';
    if ( ord(' ') <= $utf16[0] && $utf16[0] != 0x7f ) {
      if ( 0xd800 <= $utf16[0] && $utf16[0] <= 0xdbff ) {
        $surrogate = $utf16[0];
        return _FALSE;
      }
      else {
        if ( $surrogate ) {
          if ( 0xdc00 <= $utf16[0] && $utf16[0] <= 0xdfff ) {
            $utf16[1] = $utf16[0];
            $utf16[0] = $surrogate;
          }
          $surrogate = 0;
        }
        # convert UTF-16 data into Perl's internal string
        # and set UTF8 flag to on if needed
        my $ch = do {
          my $check = STRICT ? Encode::FB_CROAK : Encode::FB_QUIET;
          pop @utf16 unless $utf16[1];
          my $bytes = pack('v*', @utf16);
          my $string = decode('UTF-16LE', $bytes, $check);
        };
        $event->text( $ch );
      }
    }
    return _TRUE;
  }

=over

=item public C<< Bool _store_event(TEvent $event) >>

Store event in <get_mouse_event> and <get_key_event>

Returns true if successful.

=cut

  func _store_event(TEvent $event) {
    return _FALSE
        if $event->what == EV_NOTHING;
      
    warn('Event queue buffer overflow')
      if STRICT && @_event_queue >= _EVENT_Q_SIZE;

    # Handle event queue buffer overflow
    shift(@_event_queue)
      while @_event_queue >= _EVENT_Q_SIZE;

    return !!push(@_event_queue, $event);
  }

=item public C<< Bool _update_event_queue() >>

Reads the Windows events, converts them and updates the internal event queue.

Returns true if successful.

=cut

  func _update_event_queue() {
    my $event = TEvent->new( what => EV_NOTHING );

    my $CONSOLE = $_io->in();

    # ReadConsoleInput can sleep the process, so we first check the number
    # of available input events.
    while (my $events = $CONSOLE->GetEvents()) {

      EVENT:
      while ( $events-- ) {
        my @event = $CONSOLE->Input();
        my ($event_type) = @event;
        $event_type //= 0;

        SWITCH: for ($event_type) {

          $_ == _KEY_EVENT and do {
            my $key_event = {
              event_type        => $event[0],
              key_down          => $event[1],
              repeat_count      => $event[2],
              virtual_key_code  => $event[3],
              virtual_scan_code => $event[4],
              char              => $event[5],
              control_key_state => $event[6],
            };

            # Pasted surrogate character
            my $pasted_surrogate = $key_event->{virtual_key_code} == _VK_MENU
                                && $key_event->{char};
            
            next EVENT
              if !( $key_event->{key_down} || $pasted_surrogate );

            return _TRUE
                if _set_key_event($key_event, $event)
                && _store_event($event);

            next EVENT;
          };

          $_ == _MOUSE_EVENT and do {
            my $mouse_event = {
              event_type        => $event[0],
              mouse_position => {
                x               => $event[1],
                y               => $event[2],
              },
              button_state      => $event[3],
              control_key_state => $event[4],
              event_flags       => $event[5],
            };

            return _TRUE
                if _set_mouse_event($mouse_event, $event)
                && _store_event($event);
                
            next EVENT;
          };
        
          $_ == _WINDOW_BUFFER_SIZE_EVENT and do {
            my $window_buffer_size_event = {
              event_type  => $event[0],
              size => {
                x         => $event[1],
                y         => $event[2],
              },
            };

            return _TRUE
                if my $_set_window_buffer_size_event = do {
                  $event->what( EV_COMMAND );
                  $event->command( _CM_SCREEN_CHANGED );
                  $event->info(
                    TPoint->new(
                      x => $window_buffer_size_event->{size}->{x},
                      y => $window_buffer_size_event->{size}->{y},
                    )
                  );
                  _TRUE
                }
                && _store_event($event);

            next EVENT;
          };
  
          DEFAULT: {
            next EVENT;
          };

        }
      }
    }

    return _FALSE;
  }

=back

=cut

# ------------------------------------------------------------------------
# Initialization ---------------------------------------------------------
# ------------------------------------------------------------------------

INIT {
  # Set the console and the environment in UTF-8 mode.
  $_save_cp_input = Win32::Console::InputCP();
  Win32::Console::InputCP(_CP_UTF8);
  # Note that this must be done again after SetConsoleCP();
  setlocale( LC_ALL, ".UTF-8" );
}

END {
  # Restore the console and the environment codepage.
  Win32::Console::InputCP($_save_cp_input);
}

1;

__END__

=head1 COPYRIGHT AND LICENCE

 This file is part of the port of the Turbo Vision library.

 Copyright (c) 2019-2021 by magiblot

 This library content was taken from the framework
 "A modern port of Turbo Vision 2.0", which is licensed under MIT licence.

 POD sections by Ed Mitchell are licensed under modified CC BY-NC-ND.

=head1 AUTHORS
 
=over

=item *

2019-2021 by magiblot E<lt>magiblot@hotmail.comE<gt>

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

L<drivers.pas|https://github.com/fpc/FPCSource/blob/bdc826cc18a03a833735853c0c91268c992e8592/packages/fv/src/drivers.pas>, 
L<win32con.cpp|https://github.com/magiblot/tvision/blob/ad2a2e7ce846c3d9a7746c7ed278c00c8c1d6583/source/platform/win32con.cpp>
