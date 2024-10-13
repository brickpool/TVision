use 5.014;
use warnings;
use Test::More;
use Test::Exception;

=head1 Types

=over

=item TPoint

=cut

package TurboVision::Objects::Types {
  use Moose;
  use Moose::Util::TypeConstraints;
  use MooseX::Types -declare => [qw(
    TPoint
  )];

  class_type TPoint, {
    class => 'TurboVision::Objects::Point'
  };

  1;
}

package TurboVision::Objects::Point {
  use Function::Parameters qw ( method );
  use Moose;
  use MooseX::HasDefaults::RO;
  use MooseX::Types::Moose qw( :all );
  use namespace::autoclean;
  use TurboVision::Objects::Types qw( TPoint );

  has ['x', 'y'] => (
    is      => 'rw',
    isa     => Int,
    default => 0
  );
  
  method copy(TPoint $pt) {
    $self->x( $pt->x );
    $self->y( $pt->y );
  }
  
  __PACKAGE__->meta->make_immutable;
  1;
}

=item MouseEventType

=item TEvent

=item THardwareInfo

=item TMouse

=item TScreen

=item TVideoDriver

=cut

package TurboVision::Drivers::Types {
  use Moose;
  use Moose::Util::TypeConstraints;
  use MooseX::Types -declare => [qw(
    MouseEventType

    TEvent
    TEventQueue
    THardwareInfo
    TMouse
    TScreen

    TKeyboardDriver
    TMouseDriver
    TVideoDriver
    TSystemDriver
  )];
  use MooseX::Types::Moose qw( :all );
  use MooseX::Types::Structured qw( Dict );
  use namespace::autoclean;
  use TurboVision::Objects::Types qw( TPoint );

  subtype MouseEventType,
    as Dict[
      buttons     => Int,
      where       => TPoint,
      event_flags => Int,
    ];

  class_type TEvent, {
    class => 'TurboVision::Drivers::Event'
  };
  class_type TEventQueue, {
    class => 'TurboVision::Drivers::EventQueue'
  };
  class_type THardwareInfo, {
    class => 'TurboVision::Drivers::Hardware::Std'
  };
  class_type TMouse, {
    class => 'TurboVision::Drivers::Mouse'
  };
  class_type TScreen, {
    class => 'TurboVision::Drivers::Screen'
  };

  role_type TKeyboardDriver, {
    role => 'TurboVision::Drivers::API::Keyboard'
  };
  role_type TMouseDriver, {
    role => 'TurboVision::Drivers::API::Mouse'
  };
  role_type TVideoDriver, {
    role => 'TurboVision::Drivers::API::Video'
  };
  role_type TSystemDriver, {
    role => 'TurboVision::Drivers::API::System'
  };

  1;
}

=back

=head1 TKeyboardDriver

Define an "interface-only" role for the Keyboard driver.

  requires 'get_key_event';       # Get the next key event (non blocking)
  requires 'get_shift_state';     # Get the current shift state

=cut

package TurboVision::Drivers::API::Keyboard {
  use Moose::Role;
  use namespace::autoclean;

  requires 'get_key_event';       # Get the next key event (non blocking)
  requires 'get_shift_state';     # Get the current shift state

  1;
}

=head1 TMouseDriver 

Define an "interface-only" role for the Mouse driver.

  requires 'cursor_off';          # Hide the mouse cursor
  requires 'cursor_on';           # Show the mouse cursor
  requires 'get_button_count';    # Detect the presence of a mouse
  requires 'get_mouse_event';     # Get next mouse event from the queue

=cut

package TurboVision::Drivers::API::Mouse {
  use Moose::Role;
  use namespace::autoclean;

  requires 'cursor_off';          # Hide the mouse cursor
  requires 'cursor_on';           # Show the mouse cursor
  requires 'get_button_count';    # Detect the presence of a mouse
  requires 'get_mouse_event';     # Get next mouse event from the queue

  1;
}

=head1 TVideoDriver

Define an "interface-only" role for the Video driver.

  requires 'clear_screen';            # Clear the screen
  requires 'set_screen_mode';         # Set the video mode
  requires 'get_screen_mode';         # Return the current video mode

  requires 'set_caret_position';      # Set the cursos position
  requires 'get_caret_size';          # Get the current cursor type
  requires 'set_caret_size';          # Set the current cursos type

  requires 'get_screen_cols';         # Return current columns
  requires 'get_screen_rows';         # Return current rows
  requires 'screen_write';            # Update physical screen
  
  requires 'allocate_screen_buffer';  # Allocate screen buffer
  requires 'free_screen_buffer';      # Done screen buffer

=cut

package TurboVision::Drivers::API::Video {
  use Moose::Role;
  use namespace::autoclean;

  requires 'clear_screen';            # Clear the screen
  requires 'set_screen_mode';         # Set the video mode
  requires 'get_screen_mode';         # Return the current video mode

  requires 'set_caret_position';      # Set the cursos position
  requires 'get_caret_size';          # Get the current cursor type
  requires 'set_caret_size';          # Set the current cursos type

  requires 'get_screen_cols';         # Return current columns
  requires 'get_screen_rows';         # Return current rows
  requires 'screen_write';            # Write to the physical screen
  
  requires 'allocate_screen_buffer';  # Returns the allocated screen buffer
  requires 'free_screen_buffer';      # Releases screen buffer resources

  1;
}

=head1 TSystemDriver

Define an "interface-only" role for the System driver.

  requires 'get_tick_count';          # Return tick counts
  requires 'get_platform';            # Return $^O
  requires 'set_ctrl_brk_handler';    # System CTRL-C handler

=cut

package TurboVision::Drivers::API::System {
  use Moose::Role;
  use namespace::autoclean;

  requires 'get_tick_count';          # Return tick counts
  requires 'get_platform';            # Return $^O
  requires 'set_ctrl_brk_handler';    # System CTRL-C handler

  1;
}

=head1 TEvent

Define an "dummy" Event record.

=cut

package TurboVision::Drivers::Event {
  use Moose;
  use namespace::autoclean;

  __PACKAGE__->meta->make_immutable;
  1;
}

=head1 THardwareInfo

Platform specific driver implementation.

Adopted from the C++ Turbo Vision library.

=cut

package TurboVision::Drivers::Hardware::Std {
  use English qw( -no_match_vars );
  use Function::Parameters qw ( method );
  use MooseX::Singleton;
  use MooseX::Types::Moose qw( :all );
  use namespace::autoclean;

  use TurboVision::Drivers::Types qw(
    MouseEventType
    TEvent
  );

  with qw(
    TurboVision::Drivers::API::Keyboard
    TurboVision::Drivers::API::Mouse
    TurboVision::Drivers::API::Video
    TurboVision::Drivers::API::System
  );

=head2 Attributes

Hardware attributes.

=over

=item I<_pending_event>

  has '_pending_event' => (
    isa       => Int,
    is        => 'rw',
    default   => 0,
  );

=cut
  
  has '_pending_event' => (
    isa       => Int,
    is        => 'rw',
    default   => 0,
  );

=back

=cut

=head2 System functions

System functions adopted from the C++ Turbo Vision library.

=over

=item I<get_tick_count>

  method get_tick_count() : Int

The I<get_tick_count> function returns the number of ticks that elapsed since
the system start.

=cut

  method get_tick_count() {}
  
=item I<get_platform>

  method get_platform() : Str

The name of the operating system under which this copy of Perl was built, as
determined during the configuration process.

See also: I<$^O>

=cut

  method get_platform() { $OSNAME }

=item I<set_ctrl_brk_handler>

  method set_ctrl_brk_handler(Bool $install) : Bool

=cut

  method set_ctrl_brk_handler(Bool $install) { !!0 }

=item I<set_crit_error_handler>

  method set_crit_error_handler(Bool $install) : Bool

=cut

  method set_crit_error_handler(Bool $install) { !!1 }

=back

=cut
  
=head2 Caret functions

Caret functions adopted from the C++ Turbo Vision library.

=over

=item I<get_caret_size>

  method get_caret_size() : Int

Get the shape for the system caret. The caret shape can be a line, a halfblock,
a block or hidden.

=cut

  method get_caret_size() { 0 }

=item I<is_caret_visible>

  method is_caret_visible() : Bool

Return true if the caret is visible

=cut

  method is_caret_visible() { !!0 }

=item I<set_caret_position>

  method set_caret_position(Int $x, Int $y)

Moves the caret to the specified coordinates.

=cut

  method set_caret_position(Int $x, Int $y) {}

=item I<set_caret_size>

  method set_caret_size( Int $size )

Set the shape for the system caret. The caret shape can be a line, a halfblock,
a block or hidden.

=cut

  method set_caret_size(Int $size) {}

=back

=cut
  
=head2 Screen functions

Screen functions adopted from the C++ Turbo Vision library.

=cut

  method allocate_screen_buffer() { [] }
  method clear_screen(Int $w, Int $h) { return }
  method free_screen_buffer() {}
  method get_screen_cols() { 0 }
  method get_screen_mode() { 0 }
  method get_screen_rows() { 0 }
  method screen_write(Int $x, Int $y, ArrayRef $buf, Int $len) { return }
  method set_screen_mode(Int $mode) { return }

=head2 Mouse functions

Mouse functions adopted from the C++ Turbo Vision library.

=cut

  method cursor_off() { return; }
  method cursor_on() { return; }
  method get_button_count() { 0 }

=head2 Event functions

Event functions adopted from the C++ Turbo Vision library.

=cut

  method clear_pending_event() {
    $self->_pending_event(0);
    return;
  }
  method get_key_event(TEvent $event) { !!1 }
  method get_mouse_event(MouseEventType $me) { !!1 }
  method get_shift_state() { 0 }

  __PACKAGE__->meta->make_immutable;
  1;
}

=head1 TScreen

Video manager.

=cut

package TurboVision::Drivers::Screen {
  use Function::Parameters {
    static => {
      defaults => 'classmethod_strict',
      shift    => '$caller',
    }
  },
  qw(
    around
  );
  use Moose;
  use MooseX::StrictConstructor;
  use MooseX::Types::Moose qw( :all );
  use namespace::autoclean;
  use PerlX::Assert;
  use TurboVision::Drivers::Hardware::Std;
  use TurboVision::Drivers::Types qw(
    THardwareInfo
    TVideoDriver
  );

=head2 Constants

Defined constants:

  _FALSE
  SM_CO40, 
  SM_BW80
  SM_CO80
  SM_MONO
  SM_FONT8X8

=cut

  use constant _FALSE     => !!0;
  use constant SM_CO40    => 0x0000;
  use constant SM_BW80    => 0x0002;
  use constant SM_CO80    => 0x0003;
  use constant SM_MONO    => 0x0007;
  use constant SM_FONT8X8 => 0x0100;

=head2 Attributes

Screen attributes.

=cut

  %::__PACKAGE__ = ();

=over

=item I<check_snow>

  class_has 'check_snow' => (
    isa       => Bool,
    is        => 'rw',
    init_arg  => undef,
    builder   => 1,
  );

=cut

  # __PACKAGE__->{check_snow} = do
  {
    ACCESSOR:
    static check_snow(Maybe[Bool] $value=) {
      goto SET if @_;
      GET: {
        assert { exists __PACKAGE__->{check_snow} };
        return __PACKAGE__->{check_snow};
      }
      SET: {
        return __PACKAGE__->{check_snow} = $value;
      }
    }
    BUILDER:
    static _build_check_snow() {
      return _FALSE;
    }
    DEFAULT: {
      undef
    }
  };

=item I<cursor_lines>

  class_has 'cursor_lines' => (
    isa       => Int,
    is        => 'rwp',
    init_arg  => undef,
    builder   => 1,
  );

=cut
  
  # __PACKAGE__->{cursor_lines} = do
  {
    READER:
    static cursor_lines() {
      assert { exists __PACKAGE__->{cursor_lines} };
      return __PACKAGE__->{cursor_lines};
    }
    WRITER:
    static _cursor_lines(Int $value) {
      return __PACKAGE__->{cursor_lines} = $value;
    }
    BUILDER:
    static _build_cursor_lines() {
      $caller->get_cursor_type();
    }
    DEFAULT: {
      undef
    }
  };

=item I<hi_res_screen>

  class_has 'hi_res_screen' => (
    isa       => Bool,
    is        => 'rwp',
    lazy      => 1,
    init_arg  => undef,
    builder   => 1,
  );

=cut

  # __PACKAGE__->{hi_res_screen} = do
  {
    READER:
    static hi_res_screen() {
      assert { exists __PACKAGE__->{hi_res_screen} };
      return __PACKAGE__->{hi_res_screen};
    }
    WRITER:
    static _hi_res_screen(Bool $value) {
      return __PACKAGE__->{hi_res_screen} = $value;
    }
    BUILDER:
    static _build_hi_res_screen() {
      $caller->get_cols() > 25;
    }
    DEFAULT: {
      undef
    }
  };

=item I<screen_buffer>

  class_has 'screen_buffer' => (
    isa       => ArrayRef,
    is        => 'ro',
    init_arg  => undef,
    clearer   => 1,
    builder   => 1,
  );

=cut

  # __PACKAGE__->{screen_buffer} = do
  {
    READER:
    static screen_buffer() {
      assert { exists __PACKAGE__->{screen_buffer} };
      return __PACKAGE__->{screen_buffer};
    }
    CLEARER:
    static _clear_screen_buffer() {
      if ( exists __PACKAGE__->{screen_buffer} ) {
        $caller->get_video_driver->free_screen_buffer();
      }
      delete __PACKAGE__->{screen_buffer};
      return;
    }
    BUILDER:
    static _build_screen_buffer() {
      return $caller->get_video_driver->allocate_screen_buffer();
    }
    DEFAULT: {
      undef
    }
  };

=item I<screen_height>

  class_has 'screen_height' => (
    isa       => Int,
    is        => 'ro',
    init_arg  => undef,
  );

=cut

  # __PACKAGE__->{screen_height} = do
  {
    READER:
    static screen_height() {
      assert { exists __PACKAGE__->{screen_height} };
      return __PACKAGE__->{screen_height} = $caller->get_cols();
    }
    DEFAULT: {
      undef
    }
  };

=item I<screen_mode>

  class_has 'screen_mode' => (
    isa       => Int,
    is        => 'ro',
    init_arg  => undef,
  );

=cut

  # __PACKAGE__->{screen_mode} = do
  {
    READER:
    static screen_mode() {
      assert { exists __PACKAGE__->{screen_mode} };
      return __PACKAGE__->{screen_mode} = $caller->detect_video();
    }
    DEFAULT: {
      undef
    }
  };

=item I<screen_width>

  class_has 'screen_width' => (
    isa       => Int,
    is        => 'ro',
    init_arg  => undef,
  );

=cut

  # __PACKAGE__->{screen_width} = do
  {
    READER:
    static screen_width() {
      assert { exists __PACKAGE__->{screen_width} };
      return __PACKAGE__->{screen_width} = $caller->get_rows();
    }
    DEFAULT: {
      undef
    }
  };

=item I<startup_mode>

  class_has 'startup_mode' => (
    isa       => Int,
    is        => 'ro',
    init_arg  => undef,
    default   => 0xffff,
  );

=cut

  __PACKAGE__->{startup_mode} = do 
  {
    READER:
    static startup_mode() {
      assert { exists __PACKAGE__->{startup_mode} };
      return __PACKAGE__->{startup_mode};
    }
    DEFAULT: {
      0xffff
    }
  };

=item I<_video_driver>

  class_has '_video_driver' => (
    isa       => TVideoDriver,
    is        => 'rw',
    init_arg  => 'driver',
    reader    => 'get_video_driver',
    writer    => 'set_video_driver',
    builder   => 1,
  );

=cut

  # __PACKAGE__->{_video_driver} = do
  {
    READER:
    static get_video_driver() {
      assert { exists __PACKAGE__->{_video_driver} };
      return __PACKAGE__->{_video_driver};
    }
    WRITER:
    static set_video_driver(TVideoDriver $driver) {
      return __PACKAGE__->{_video_driver} = $driver;
    }
    BUILDER:
    static _build_video_driver() {
      return THardwareInfo->instance;
    }
    DEFAULT: {
      undef;
    }
  };

=back

=cut

=head2 Constructor/Destructor

Initializes/terminates video manager

=cut

  around BUILDARGS(%args) {
    if ( exists $args{driver} ) {
      my $driver = delete $args{driver};
      if ( is_TVideoDriver $driver ) {
        __PACKAGE__->{_video_driver} = $driver;
      }
      else {
        confess "Invalid argument 'driver => $driver'";
      }
    }
    $self->$orig(%args);
  }
  sub BUILD {
    shift->init_video();
  }
  sub DEMOLISH {
    shift->done_video();
  }
  static init_video() {
    return if __PACKAGE__->{startup_mode} != 0xffff;

    BUILD: {
      __PACKAGE__->{_video_driver}  //= $caller->_build_video_driver();
      __PACKAGE__->{check_snow}     //= $caller->_build_check_snow();
      __PACKAGE__->{cursor_lines}   //= $caller->_build_cursor_lines();
      __PACKAGE__->{hi_res_screen}  //= $caller->_build_hi_res_screen();
      __PACKAGE__->{screen_buffer}  //= $caller->_build_screen_buffer();
    }

    __PACKAGE__->{startup_mode} = $caller->detect_video();
    $caller->set_cursor_type(0);
    return;
  }
  static done_video() {
    CLEAR: {
      my $ref = __PACKAGE__;
      no strict 'refs';
      %$ref = ();
    }
    __PACKAGE__->{startup_mode} = 0xffff;
    return;
  }

=head2 Functions

Screen functions adopted from the Pascal Turbo Vision library.

=cut

  static clear_screen() {
    confess if not $caller->get_video_driver;
    WITH: for ( $caller->get_video_driver ) {
      $_->clear_screen($_->get_screen_rows, $_->get_screen_cols);
    }
  }
  static detect_video() {
    my $mode = $caller->get_crt_mode();
    return $caller->fix_crt_mode($mode);
  }
  static fix_crt_mode(Int $mode) {
    SWITCH: for ( $mode ) {
      ($_ & 0xff) == (40 << 8 + 25) && do {
        $mode = SM_CO40;
        last;
      };
      $_ == (80 << 8 + 25) && do {
        $mode = SM_CO80;
        last;
      };
      ($_ & 0xff) > 25 && do {
        $mode = SM_CO80 + SM_FONT8X8;
        last;
      };
      $_ < 0 || $_ > 0x7fff && do {
        $mode = SM_CO80;
      };
    }
    return $mode;
  }
  static get_crt_mode() {
    confess if not $caller->get_video_driver;
    return $caller->get_video_driver->get_screen_mode();
  }
  static set_crt_mode(Int $mode) {
    confess if not $caller->get_video_driver;
    $caller->get_video_driver->set_screen_mode($mode);
    return;
  }
  static set_video_mode(Int $mode) {
    __PACKAGE__->{screen_mode} = class->fix_crt_mode($mode);
    SWITCH: for ( $mode ) {
      $_ == SM_CO40 && do {
        $mode = 40 << 8 + 25;
        last;
      };
      ( $_ == SM_BW80 
          || 
        $_ == SM_CO80 
          || 
        $_ == SM_MONO 
      ) && do {
        $mode = 80 << 8 + 25;
        last;
      };
      ( $_ == SM_BW80 + SM_FONT8X8 
          ||
        $_ == SM_CO80 + SM_FONT8X8 
      ) && do {
        $mode = 80 << 8 + 50;
        last;
      };
    }
    $caller->set_crt_mode(__PACKAGE__->{screen_mode});
    return __PACKAGE__->{screen_mode};
  }

=head2 Additional functions

Screen functions adopted from the C++ Turbo Vision library.

=cut

  static get_cols() {
    confess if not $caller->get_video_driver;
    return $caller->get_video_driver->get_screen_cols();
  }
  static get_rows() {
    confess if not $caller->get_video_driver;
    return $caller->get_video_driver->get_screen_rows();
  }
  static get_cursor_type() {
    confess if not $caller->get_video_driver;
    return $caller->get_video_driver->get_caret_size();
  }
  static screen_write(Int $x, Int $y, ArrayRef $buf, Int $len) {
    confess if not $caller->get_video_driver;
  }
  static set_cursor_type(Int $type) {
    confess if not $caller->get_video_driver;
    $caller->get_video_driver->set_caret_size($type);
    return;
  }
  
  __PACKAGE__->meta->make_immutable;
  1;
}

=head1 TMouse

Mouse Interface.

=cut

package TurboVision::Drivers::Mouse {
  use Function::Parameters {
    static => {
      defaults => 'classmethod_strict',
      shift    => '$caller',
    }
  },
  qw(
    around
  );
  use Moose;
  use MooseX::StrictConstructor;
  use MooseX::Types::Moose qw( :all );
  use namespace::autoclean;
  use PerlX::Assert;
  use TurboVision::Drivers::Hardware::Std;
  use TurboVision::Drivers::Types qw(
    MouseEventType
    TMouseDriver
    THardwareInfo
  );
  use TurboVision::Objects::Point;
  use TurboVision::Objects::Types qw( TPoint );

=head2 Constants

Defined constants:

  _FALSE

=cut

  use constant _FALSE => !!0;

=head2 Variables

Used variables.

  my $me;

=cut

  my $me = {
    buttons     => 0,
    where       => TPoint->new(),
    event_flags => 0,
  };

=head2 Attributes

Mouse attributes.

=cut

  %::__PACKAGE__ = ();

=over

=item I<button_count>

  class_has 'button_count' => (
    isa       => Int,
    is        => 'ro',
    init_arg  => undef,
    builder   => 1,
  );

=cut

  # __PACKAGE__->{button_count} = do
  {
    READER:
    static button_count() {
      assert { exists __PACKAGE__->{button_count} };
      return __PACKAGE__->{button_count};
    }
    BUILDER:
    static _built_button_count() {
      confess if not $caller->get_mouse_driver;
      return $caller->get_mouse_driver->get_button_count;
    }
    DEFAULT: {
      undef
    }
  };

=item I<mouse_buttons>

  class_has 'mouse_buttons' => (
    isa       => Int,
    is        => 'ro',
    init_arg  => undef,
  );

=cut

  # __PACKAGE__->{mouse_buttons} = do
  {
    READER:
    static mouse_buttons() {
      assert { exists __PACKAGE__->{mouse_buttons} };
      $caller->get_event($me);
      return __PACKAGE__->{mouse_buttons} = $me->{buttons};
    }
    DEFAULT: {
      undef
    }
  };

=item I<mouse_int_flag>

  class_has 'mouse_int_flag' => (
    isa       => Int,
    is        => 'ro',
    init_arg  => undef,
  );

=cut

  # __PACKAGE__->{mouse_int_flag} = do
  {
    READER:
    static mouse_int_flag() {
      assert { exists __PACKAGE__->{mouse_int_flag} };
      $caller->get_event($me);
      return __PACKAGE__->{mouse_int_flag} = $me->{event_flags}
    }
    DEFAULT: {
      undef
    }
  };

=item I<mouse_reverse>

  class_has 'mouse_reverse' => (
    isa       => Bool,
    is        => 'ro',
    init_arg  => undef,
    default   => _FALSE,
  );

=cut

  __PACKAGE__->{mouse_reverse} = do
  {
    READER:
    static mouse_reverse() {
      return __PACKAGE__->{mouse_reverse};
    }
    DEFAULT: {
      _FALSE
    }
  };

=item I<mouse_where>

  class_has 'mouse_where' => (
    isa       => TPoint,
    is        => 'ro',
    init_arg  => undef,
    default   => sub { TPoint->new },
  );

=cut

  __PACKAGE__->{mouse_where} = do
  {
    READER:
    static mouse_where() {
      $caller->get_event($me);
      __PACKAGE__->{mouse_where}->copy($me->{where});
      return __PACKAGE__->{mouse_where};
    }
    DEFAULT: {
      TPoint->new()
    }
  };

=item I<_mouse_driver>

  class_has '_mouse_driver' => (
    isa       => TMouseDriver,
    is        => 'rw',
    init_arg  => 'driver',
    reader    => 'get_mouse_driver',
    writer    => 'set_mouse_driver',
    builder   => 1,
  );

=cut

  # __PACKAGE__->{_mouse_driver} = do
  {
    READER:
    static get_mouse_driver() {
      assert { exists __PACKAGE__->{_mouse_driver} };
      return __PACKAGE__->{_mouse_driver};
    }
    WRITER:
    static set_mouse_driver(TMouseDriver $driver) {
      return __PACKAGE__->{_mouse_driver} = $driver;
    }
    BUILDER:
    static _build_mouse_driver() {
      return THardwareInfo->instance;
    }
    DEFAULT: {
      undef;
    }
  };

=back

=head2 Constructor/Destructor.

Adopted from the Pascal Turbo Vision library.

=cut

  around BUILDARGS(%args) {
    if ( exists $args{driver} ) {
      my $driver = delete $args{driver};
      if ( is_TMouseDriver $driver ) {
        __PACKAGE__->{_mouse_driver} = $driver;
      }
      else {
        confess "Invalid argument 'driver => $driver'";
      }
    }
    $self->$orig(%args);
  }
  sub BUILD {
    shift->resume();
  }
  sub DEMOLISH {
    shift->suspend();
  }

=head2 Functions

Mouse functions adopted from the Pascal Turbo Vision library.

=cut
  
  static hide_mouse() {
    confess if not $caller->get_mouse_driver;
    $caller->get_mouse_driver->cursor_off();
  }
  static show_mouse() {
    confess if not $caller->get_mouse_driver;
    $caller->get_mouse_driver->cursor_on();
  }

=head2 Additional functions

Mouse functions adopted from the C++ Turbo Vision library.

=cut
  
  static get_event(MouseEventType $me) {
    confess if not $caller->get_mouse_driver;
    $caller->get_mouse_driver->get_mouse_event($me);
  }
  static present() {
    return $caller->button_count != 0;
  }
  static resume() {
    BUILD: {
      __PACKAGE__->{_mouse_driver}  //= $caller->_build_mouse_driver();
      __PACKAGE__->{button_count}   //= $caller->_built_button_count();
    }
    return;
  }
  static suspend() {
    CLEAR:
    delete __PACKAGE__->{$_} for qw(
      button_count
      mouse_buttons
      mouse_int_flag
      _mouse_driver
    );
    return;
  }

  __PACKAGE__->meta->make_immutable;
  1;
}

=head1 TEventQueue

Event manager.

=cut

package TurboVision::Drivers::EventQueue {
  use Function::Parameters {
    static => {
      defaults => 'classmethod_strict',
      shift    => '$caller',
    }
  };
  use Moose;
  use MooseX::ClassAttribute;
  use MooseX::HasDefaults::RO;
  use MooseX::StrictConstructor;
  use MooseX::Types::Moose qw( :all );
  use namespace::autoclean;
  use PerlX::Assert;
  use TurboVision::Drivers::Types qw(
    TEvent
    TMouse
  );

=head2 Constructor/Destructor

Initializes/terminates event manager.

=cut

  sub BUILD {
    shift->init_events();
  }
  sub DEMOLISH {
    shift->done_events();
  }
  static init_events() {
    BUILD: {
      __PACKAGE__->{_mouse} //= $caller->_build_mouse();
    }
    confess if not $caller->_mouse;
    $caller->mouse_events($caller->_mouse->present);
    return;
  }
  static done_events() {
    CLEAR:
    delete __PACKAGE__->{_mouse};
    return;
  }

=head2 Constants

Defined constants:

  _FALSE

=cut

  use constant _FALSE => !!0;

=head2 Attributes

Mouse Event attributes.

=cut

  %::__PACKAGE__ = ();

=over

=item I<double_delay>

  class_has 'double_delay' => (
    isa       => Int,
    is        => 'rw',
    init_arg  => undef,
    default   => 8,
  );

=cut
  
  __PACKAGE__->{double_delay} = do
  {
    ACCESSOR:
    static double_delay(Maybe[Int] $value=) {
      goto SET if @_;
      GET: {
        return __PACKAGE__->{double_delay};
      }
      SET: {
        return __PACKAGE__->{double_delay} = $value;
      }
    }
    DEFAULT: {
      8
    }
  };

=item I<mouse_events>

  class_has 'mouse_events' => (
    isa       => Bool,
    is        => 'rw',
    init_arg  => undef,
    default   => _FALSE,
  );

=cut
  
  __PACKAGE__->{mouse_events} = do
  {
    ACCESSOR:
    static mouse_events(Maybe[Bool] $value=) {
      goto SET if @_;
      GET: {
        return __PACKAGE__->{mouse_events};
      }
      SET: {
        return __PACKAGE__->{mouse_events} = $value;
      }
    }
    DEFAULT: {
      _FALSE
    }
  };

=item I<repeat_delay>

  class_has 'repeat_delay' => (
    isa       => Int,
    is        => 'rw',
    init_arg  => undef,
    default   => 8,
  );

=cut
  
  __PACKAGE__->{repeat_delay} = do
  {
    static repeat_delay(Maybe[Int] $value=) {
      goto SET if @_;
      GET: {
        return __PACKAGE__->{repeat_delay};
      }
      SET: {
        return __PACKAGE__->{repeat_delay} = $value;
      }
    }
    DEFAULT: {
      8
    }
  };

=back

=cut

=head2 Additional attributes

Event attributes adopted from the C++ Turbo Vision library.

=over

=item I<_mouse>

  class_has '_mouse' => (
    isa       => TMouse,
    is        => 'ro',
    init_arg  => undef,
    builder   => 1,
  );

=cut

  # __PACKAGE__->{_mouse} = do
  {
    READER:
    static _mouse() {
      assert { exists __PACKAGE__->{_mouse} };
      return __PACKAGE__->{_mouse};
    }
    BUILDER:
    static _build_mouse() {
      return TMouse->new;
    }
    DEFAULT: {
      undef;
    }
  };

=back

=cut

=head2 Functions

Event functions adopted from the Pascal Turbo Vision library.

=cut

  static get_mouse_event( TEvent $event ) {
    confess if not $caller->_mouse;
    return;
  }
  static get_key_event( TEvent $event ) {
    return;
  }

  __PACKAGE__->meta->make_immutable;
  1;
}

=head1 TSystemError

System error handler.

=cut

package TurboVision::Drivers::SystemError {
  use Function::Parameters {
    static => {
      defaults => 'classmethod_strict',
      shift    => '$caller',
    }
  };
  use Moose;
  use MooseX::HasDefaults::RO;
  use MooseX::StrictConstructor;
  use MooseX::Types::Moose qw( :all );
  use namespace::autoclean;

  use constant _FALSE => !!0;

=head2 Constructor/Destructor

Initializes/terminates system error handler.

=cut

  sub BUILD {
    shift->init_sys_error();
  }
  sub DEMOLISH {
    shift->done_sys_error();
  }
  static init_sys_error() {
    return;
  }
  static done_sys_error() {
    return;
  }

=head2 Attributes

Mouse System attributes.

=over

=cut

  %::__PACKAGE__ = ();

=item I<save_ctrl_break>

  class_has 'save_ctrl_break' => (
    isa       => Bool,
    is        => 'ro',
    init_arg  => undef,
    default   => _FALSE,
  );

=cut
  
  __PACKAGE__->{save_ctrl_break} = do
  {
    READER:
    static save_ctrl_break() {
      return __PACKAGE__->{save_ctrl_break};
    }
    DEFAULT: {
      _FALSE
    }
  };

=item I<sys_color_attr>

  class_has 'sys_color_attr' => (
    isa       => Int,
    is        => 'ro',
    init_arg  => undef,
    default   => 0x4e4f,
  );

=cut
  
  __PACKAGE__->{sys_color_attr} = do
  {
    READER:
    static sys_color_attr() {
      return __PACKAGE__->{sys_color_attr};
    }
    DEFAULT: {
      0x4e4f
    }
  };

=item I<sys_err_active>

  class_has 'sys_err_active' => (
    isa       => Bool,
    is        => 'ro',
    init_arg  => undef,
    default   => _FALSE,
  );

=cut
  
  __PACKAGE__->{sys_err_active} = do
  {
    READER:
    static sys_err_active() {
      return __PACKAGE__->{sys_err_active};
    }
    DEFAULT: {
      _FALSE
    }
  };

=item I<sys_error_func>

  class_has 'sys_error_func' => (
    isa       => CodeRef,
    is        => 'ro',
    init_arg  => undef,
    default   => _FALSE,
  );

=cut
  
  __PACKAGE__->{sys_error_func} = do
  {
    READER:
    static sys_error_func() {
      return __PACKAGE__->{sys_error_func};
    }
    DEFAULT: {
      \&system_error
    }
  };

=item I<sys_mono_attr>

  class_has 'sys_mono_attr' => (
    isa       => Int,
    is        => 'ro',
    init_arg  => undef,
    default   => 0x7070,
  );

=cut
  
  __PACKAGE__->{sys_mono_attr} = do
  {
    READER:
    static sys_mono_attr() {
      return __PACKAGE__->{sys_mono_attr};
    }
    DEFAULT: {
      0x7070
    }
  };

=back

=cut

=head2 Functions

System function adopted from the Pascal Turbo Vision library.

=cut

  static system_error(Int $error_code, Int $drive) {}

  __PACKAGE__->meta->make_immutable;
  1;
}

=head1 main

Test cases.

=cut

BEGIN {
  use_ok 'TurboVision::Objects::Types', qw( TPoint );
  use_ok 'TurboVision::Objects::Point';
  use_ok 'TurboVision::Drivers::Types', qw(
    TEvent
    TEventQueue
    THardwareInfo
    TMouse
    TScreen
  );
  use_ok 'TurboVision::Drivers::Hardware::Std';
  use_ok 'TurboVision::Drivers::Screen';
  use_ok 'TurboVision::Drivers::Mouse';
  use_ok 'TurboVision::Drivers::EventQueue';
}

isa_ok( TPoint->new(), TPoint->class() );
isa_ok( TEvent->new(), TEvent->class() );
isa_ok( THardwareInfo->new(), THardwareInfo->class() );

#--------------
note 'TScreen';
#--------------
subtest 'TScreen->new(driver => $driver)' => sub {
  plan tests => 2;
  my $scr;
  lives_ok( sub { $scr = TScreen->new(driver => THardwareInfo->instance) } );
  isa_ok( $scr, TScreen->class() );
};

lives_ok(
  sub { TScreen->init_video },
  'TScreen->init_video'
);

ok (
  !TScreen->check_snow,
  '!TScreen->check_snow'
);
lives_ok(
  sub {
    no strict 'refs';
    TurboVision::Drivers::Screen->{check_snow} = 1
  },
  'TurboVision::Drivers::Screen->{check_snow} = 1'
);
is (
  TScreen->check_snow,
  1,
  'TScreen->check_snow == 1'
);
lives_ok(
  sub {
    no strict 'refs';
    TScreen->class->{cursor_lines} = 0x0607
  },
  'TScreen->class->{cursor_lines} = 0x0607'
);
is (
  TScreen->cursor_lines,
  0x0607,
  'TScreen->cursor_lines == 0x0607'
);
lives_ok(
  sub { TScreen->done_video },
  'TScreen->done_video'
);
is (
  do {
    no strict 'refs';
    TurboVision::Drivers::Screen->{startup_mode}
  },
  0xffff,
  'TurboVision::Drivers::Screen->{startup_mode} == 0xffff'
);

#------------
note 'TMouse';
#------------
my $mouse = new_ok( TMouse->class() );
lives_ok(
  sub { TMouse->show_mouse },
  'TMouse->show_mouse'
);
lives_ok(
  sub { $mouse = undef },
  'TMouse->DEMOLISH'
);

lives_ok(
  sub { TMouse->resume },
  'TMouse->resume'
);
is(
  TMouse->button_count,
  0,
  'TMouse->button_count'
);
ok(
  is_TPoint( TMouse->mouse_where ),
  'TMouse->mouse_where'
);
lives_ok(
  sub {
    no strict 'refs';
    TurboVision::Drivers::Mouse->{mouse_where}->x
  },
  'TMouse->class->{mouse_where}->x'
);
lives_ok(
  sub { TMouse->hide_mouse },
  'TMouse->hide_mouse'
);
lives_ok(
  sub { TMouse->suspend },
  'TMouse->suspend'
);

#------------------
note 'TEventQueue';
#-----------------
my $event_q = new_ok( TEventQueue->class() );
lives_ok(
  sub { TEventQueue->_mouse },
  'TEventQueue->_mouse'
);

lives_ok(
  sub { $event_q = undef },
  'TEventQueue->DEMOLISH'
);

lives_ok(
  sub { TEventQueue->init_events },
  'TEventQueue->init_events'
);
is(
  TEventQueue->double_delay,
  8,
  'TEventQueue->double_delay'
);
ok(
  !TEventQueue->mouse_events,
  'TEventQueue->mouse_events'
);
is(
  TEventQueue->repeat_delay,
  8,
  'TEventQueue->repeat_delay == 8'
);
lives_ok(
  sub { TEventQueue->repeat_delay(9) },
  'TEventQueue->repeat_delay(9)'
);
is(
  TEventQueue->repeat_delay,
  9,
  'TEventQueue->repeat_delay == 9'
);
lives_ok(
  sub {
    my $event = TEvent->new();
    TEventQueue->get_mouse_event($event);
  },
  'TEventQueue->get_mouse_event'
);

lives_ok(
  sub { TEventQueue->done_events },
  'TEventQueue->done_events'
);

done_testing();
