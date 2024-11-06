package TV::Drivers::Event;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TEvent
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Hash::Util qw( lock_hash );
use Scalar::Util qw( blessed );
use Tie::Hash;

use TV::Drivers::Const qw( 
  :evXXXX
  KB_ALT_SHIFT
  KB_ALT_SPACE
  KB_DEL
  KB_CTRL_SHIFT
  KB_CTRL_DEL
  KB_SHIFT
  KB_SHIFT_DEL
  KB_INS
  KB_CTRL_INS
  KB_SHIFT_INS
);
use TV::Drivers::HardwareInfo;

# The following code section represents the 'MouseEventType' structure used for 
# the 'THWMouse' and 'TEvent' class.
package MouseEventType {
  use strict;
  use warnings;

  use Devel::StrictMode;
  use Devel::Assert STRICT ? 'on' : 'off';
  use if STRICT => 'Hash::Util';
  use Scalar::Util qw( blessed );
  use TV::Objects::Point;

  sub new {    # $obj (%args)
    no warnings 'uninitialized';
    my ( $class, %args ) = @_;
    assert ( $class and !ref $class );
    my $self = {
      eventFlags      => 0+ $args{eventFlags},
      controlKeyState => 0+ $args{controlKeyState},
      buttons         => 0+ $args{buttons},
    };
    my $type = ref $args{where};
    if ( $type eq 'HASH' || $type eq TPoint ) {
      $self->{where} = TPoint->new(
        x => 0+ $args{where}{x},
        y => 0+ $args{where}{y},
      );
    }
    elsif ( $type eq 'ARRAY' ) {
      $self->{where} = TPoint->new(
        x => 0+ $args{where}->[0],
        y => 0+ $args{where}->[1],
      );
    } 
    else {
      $self->{where} = TPoint->new();
    }
    bless $self, $class;
    Hash::Util::lock_keys( %$self ) if STRICT;
    return $self;
  } #/ sub MouseEventType::new

  sub clone {    # $obj ()
    my $self = shift;
    assert ( blessed $self );
    my $clone = { %$self };
    $clone->{where} = $self->{where}->clone();
    bless $clone, ref $self;
    Hash::Util::lock_keys( %$clone ) if STRICT;
    return $clone;
  }

  $INC{"MouseEventType.pm"} = 1;
}

# The following code section represents the 'CharScanType' structure used for 
# the 'KeyDownEvent' class.
package CharScanType {
  use strict;
  use warnings;

  use Devel::StrictMode;
  use Devel::Assert STRICT ? 'on' : 'off';
  use Hash::Util qw( lock_hash );
  use Tie::Hash;

  our %FIELDS = (
    scanCode => sub {
      no warnings 'uninitialized';
      my ( $this, $code ) = @_;
      $$this = ($$this & 0xff) + (0+$code << 8) if @_ > 1;
      $$this >> 8;
    },
    charCode => sub { 
      no warnings 'uninitialized';
      my ( $this, $code ) = @_;
      $$this = ($$this & ~0xff) + (0+$code & 0xff) if @_ > 1;
      $$this & 0xff;
    },
  );
  lock_hash( %FIELDS );

  use parent 'Tie::Hash';

  sub new {    # $obj (%args)
    my ( $class, %args ) = @_;
    assert ( $class and !ref $class );
    my $self = bless {}, $class;
    tie %$self, $class;
    map { $self->{$_} = $args{$_} }
      grep { exists $args{$_} }
        keys %FIELDS;
    return $self;
  }

  sub TIEHASH  { bless \( my $data ), $_[0] }
  sub STORE    { $FIELDS{ $_[1] }->( $_[0], $_[2] ) }
  sub FETCH    { $FIELDS{ $_[1] }->( $_[0] ) }
  sub FIRSTKEY { my $a = scalar keys %FIELDS; each %FIELDS }
  sub NEXTKEY  { each %FIELDS }
  sub EXISTS   { exists $FIELDS{ $_[1] } }
  sub DELETE   { delete $FIELDS{ $_[1] } }  # raise an exception
  sub CLEAR    { %FIELDS = () }             # raise an exception
  sub SCALAR   { scalar keys %FIELDS }      # return number of elements (> 5.24)

  $INC{"CharScanType.pm"} = 1;
}

# The following code section represents the 'KeyDownEvent' structure used for 
# the 'TEvent' class.
package KeyDownEvent {
  use strict;
  use warnings;

  use Devel::StrictMode;
  use Devel::Assert STRICT ? 'on' : 'off';
  use Hash::Util qw( lock_hash );
  use Tie::Hash;

  our %FIELDS = (
    keyCode => sub {
      no warnings 'uninitialized';
      my ( $this, $code ) = @_;
      my $obj = tied %{ $this->[0] };
      $$obj = 0+$code if @_ > 1;
      $$obj;
    },
    charScan => sub {
      my ( $this, $obj ) = @_;
      $this->[0] = $obj if @_ > 1;
      $this->[0];
    },
    controlKeyState => sub { 
      no warnings 'uninitialized';
      my ( $this, $state ) = @_;
      $this->[1] = 0+$state if @_ > 1;
      $this->[1];
    },
  );
  lock_hash( %FIELDS );

  use parent 'Tie::Hash';

  sub new {    # $obj (%args)
    my ( $class, %args ) = @_;
    assert ( $class and !ref $class );
    my $self = bless {}, $class;
    tie %$self, $class;
    map { $self->{$_} = $args{$_} }
      grep { exists $args{$_} }
        keys %FIELDS;
    return $self;
  }

  sub TIEHASH  { bless [ CharScanType->new(), 0 ], $_[0] }
  sub STORE    { $FIELDS{ $_[1] }->( $_[0], $_[2] ) }
  sub FETCH    { $FIELDS{ $_[1] }->( $_[0] ) }
  sub FIRSTKEY { my $a = scalar keys %FIELDS; each %FIELDS }
  sub NEXTKEY  { each %FIELDS }
  sub EXISTS   { exists $FIELDS{ $_[1] } }
  sub DELETE   { delete $FIELDS{ $_[1] } }  # raise an exception
  sub CLEAR    { %FIELDS = () }             # raise an exception
  sub SCALAR   { scalar keys %FIELDS }      # return number of elements (> 5.24)

  $INC{"KeyDownEvent.pm"} = 1;
}

# The following code section represents the 'MessageEvent' structure used for
# the 'TEvent' class.
package MessageEvent {
  use strict;
  use warnings;

  use Devel::StrictMode;
  use Devel::Assert STRICT ? 'on' : 'off';
  use Hash::Util qw( lock_hash );
  use Hash::Util::FieldHash qw( register id_2obj );
  use Scalar::Util qw( refaddr );
  use Tie::Hash;

  our %FIELDS = (
    command => sub {
      no warnings 'uninitialized';
      my ( $this, $cmd ) = @_;
      $this->[0] = 0+$cmd if @_ > 1;
      $this->[0];
    },
    infoPtr => sub {
      no warnings 'uninitialized';
      my ( $this, $ref ) = @_;
      if ( @_ > 1 ) {
        my $id = refaddr $ref;
        register( $ref ) if $id;
        $this->[1] = 0+$id;
      }
      id_2obj $this->[1];
    },
    infoLong => sub {
      no warnings 'uninitialized';
      my ( $this, $info ) = @_;
      $this->[1] = $info & 0xffff_ffff if @_ > 1;
      $this->[1] & 0xffff_ffff;
    },
    infoWord => sub {
      no warnings 'uninitialized';
      my ( $this, $info ) = @_;
      $this->[1] = $info & 0xffff if @_ > 1;
      $this->[1] & 0xffff;
    },
    infoInt => sub {
      no warnings 'uninitialized';
      my ( $this, $info ) = @_;
      $this->[1] = 0+$info if @_ > 1;
      $this->[1];
    },
    infoByte => sub {
      no warnings 'uninitialized';
      my ( $this, $info ) = @_;
      $this->[1] = $info & 0xff if @_ > 1;
      $this->[1] & 0xff;
    },
    infoChar => sub {
      no warnings 'uninitialized';
      my ( $this, $info ) = @_;
      $this->[1] = ord $_[1] if @_ > 1;
      chr $this->[1];
    },
  );
  lock_hash( %FIELDS );

  use parent 'Tie::Hash';

  sub new {    # $obj (%args)
    my ( $class, %args ) = @_;
    assert ( $class and !ref $class );
    my $self = bless {}, $class;
    tie %$self, $class;
    map { $self->{$_} = $args{$_} }
      grep { exists $args{$_} }
        keys %FIELDS;
    return $self;
  } #/ sub new

  sub TIEHASH  { bless [ 0, 0 ], $_[0] }
  sub STORE    { $FIELDS{ $_[1] }->( $_[0], $_[2] ) }
  sub FETCH    { $FIELDS{ $_[1] }->( $_[0] ) }
  sub FIRSTKEY { my $a = scalar keys %FIELDS; each %FIELDS }
  sub NEXTKEY  { each %FIELDS }
  sub EXISTS   { exists $FIELDS{ $_[1] } }
  sub DELETE   { delete $FIELDS{ $_[1] } }  # raise an exception
  sub CLEAR    { %FIELDS = () }             # raise an exception
  sub SCALAR   { scalar keys %FIELDS }      # return number of elements (> 5.24)

  $INC{"MessageEvent.pm"} = 1;
}

sub TEvent() { __PACKAGE__ }

our %FIELDS = (
  what => sub {
    my ( $this, $what ) = @_;
    if ( @_ > 1 ) {
      no warnings 'uninitialized';
      $what += EV_NOTHING;
      my $type = ref $this->[1];
      if ( $what == EV_NOTHING && $type ) {
        @$this = ( EV_NOTHING, undef );
      }
      elsif ( ( $what & EV_MOUSE ) && $type ne 'MouseEventType' ) {
        @$this = ( $what, MouseEventType->new() );
      }
      elsif ( ( $what & EV_KEYBOARD ) && $type ne 'KeyDownEvent' ) {
        @$this = ( $what, KeyDownEvent->new() );
      }
      elsif ( ( $what & EV_MESSAGE ) && $type ne 'MessageEvent' ) {
        @$this = ( $what, MessageEvent->new() );
      }
      else {
        $this->[0] = $what;
      }
    }
    $this->[0];
  },
  mouse => sub {
    no warnings 'uninitialized';
    my ( $this, $mouse ) = @_;
    $this->[1] = $mouse if @_ > 1;
    my $type = ref $this->[1];
    $type =~ /mouse/i ? $this->[1] : undef;
  },
  keyDown => sub {
    no warnings 'uninitialized';
    my ( $this, $keyDown ) = @_;
    $this->[1] = $keyDown if @_ > 1;
    my $type = ref $this->[1];
    $type =~ /keyDown/i ? $this->[1] : undef;
  },
  message => sub {
    no warnings 'uninitialized';
    my ( $this, $message ) = @_;
    $this->[1] = $message if @_ > 1;
    my $type = ref $this->[1];
    $type =~ /message/i ? $this->[1] : undef;
  },
);
lock_hash( %FIELDS );

use parent 'Tie::Hash';

sub new {    # $obj (%args)
  no warnings 'uninitialized';
  my ( $class, %args ) = @_;
  assert ( $class and !ref $class );
  my $self = bless {}, $class;
  tie %$self, $class;
  my $this = tied %$self;
  if ( $args{what} & EV_MOUSE ) {
    $this->[0] = $args{what},
    $this->[1] = MouseEventType->new(
      map { $_ => $args{mouse}{$_} }
        grep { exists $args{mouse}{$_} } 
          qw( where eventFlags controlKeyState buttons )
    );
  }
  elsif ( $args{what} & EV_KEYBOARD ) {
    $this->[0] = $args{what},
    $this->[1] = KeyDownEvent->new( 
      map { $_ => $args{keyDown}{$_} }
        grep { exists $args{keyDown}{$_} } 
          qw( keyCode charScan controlKeyState )
    );
  }
  elsif ( $args{what} & EV_MESSAGE ) {
    $this->[0] = $args{what},
    $this->[1] = MessageEvent->new( 
      map { $_ => $args{message}{$_} }
        grep { exists $args{message}{$_} } 
          qw( command infoPtr infoLong infoWord infoInt infoByte infoChar )
    );
  }
  return $self;
} #/ sub new

sub TIEHASH  { bless [ EV_NOTHING, undef ], $_[0] }
sub STORE    { $FIELDS{ $_[1] }->( $_[0], $_[2] ) }
sub FETCH    { $FIELDS{ $_[1] }->( $_[0] ) }
sub FIRSTKEY { my $a = scalar keys %FIELDS; each %FIELDS }
sub NEXTKEY  { each %FIELDS }
sub EXISTS   { exists $FIELDS{ $_[1] } }
sub DELETE   { delete $FIELDS{ $_[1] } }  # raise an exception
sub CLEAR    { %FIELDS = () }             # raise an exception
sub SCALAR   { scalar keys %FIELDS }      # return number of elements (> 5.24)

sub getMouseEvent {    # void ($self)
  assert ( blessed $_[0] );
  require TV::Drivers::EventQueue;
  TV::Drivers::EventQueue->getMouseEvent( $_[0] );
  return;
}

sub getKeyEvent {    # void ($self)
  assert ( blessed $_[0] );
  if ( THardwareInfo->getKeyEvent( $_[0] ) ) {
    my $self = shift;

    # Need to handle special case of Alt-Space, Ctrl-Ins, Shift-Ins,
    # Ctrl-Del, Shift-Del

    SWITCH: for ( $self->{keyDown}{keyCode} ) {
      $_ == ord(' ') and do {
        if ( $self->{keyDown}{controlKeyState} & KB_ALT_SHIFT ) {
          $self->{keyDown}{keyCode} = KB_ALT_SPACE;
        }
        last;
      };
      $_ == KB_DEL and do {
        if ( $self->{keyDown}{controlKeyState} & KB_CTRL_SHIFT ) {
          $self->{keyDown}{keyCode} = KB_CTRL_DEL;
        }
        elsif ( $self->{keyDown}{controlKeyState} & KB_SHIFT ) {
          $self->{keyDown}{keyCode} = KB_SHIFT_DEL;
        }
        last;
      };
      $_ == KB_INS and do {
        if ( $self->{keyDown}{controlKeyState} & KB_CTRL_SHIFT ) {
          $self->{keyDown}{keyCode} = KB_CTRL_INS;
        }
        elsif ( $self->{keyDown}{controlKeyState} & KB_SHIFT ) {
          $self->{keyDown}{keyCode} = KB_SHIFT_INS;
        }
        last;
      };
    } #/ SWITCH: for ( $self->{keyDown}{...})
  } #/ if ( THardwareInfo->getKeyEvent...)
  else {
    $_[0]->{what} = EV_NOTHING;
  }
  return;
} #/ sub getKeyEvent

1
