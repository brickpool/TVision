package TV::Drivers::Event;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TEvent
  new_TEvent
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Hash::Util qw( lock_hash );
use Scalar::Util qw(
  blessed
  looks_like_number
);
use Tie::Hash;

use TV::Drivers::Const qw( 
  :evXXXX
  kbAltShift
  kbAltSpace
  kbDel
  kbCtrlShift
  kbCtrlDel
  kbShift
  kbShiftDel
  kbIns
  kbCtrlIns
  kbShiftIns
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

  our %HAS; BEGIN {
    %HAS = ( 
      eventFlags      => sub { 0 },
      controlKeyState => sub { 0 },
      buttons         => sub { 0 },
      where           => sub { TPoint->new() },
    );
  }

  sub new {    # $obj (%args)
    no warnings 'uninitialized';
    my ( $class, %args ) = @_;
    assert ( $class and !ref $class );
    my $self = {
      eventFlags      => 0+ $args{eventFlags}      || $HAS{eventFlags}->(),
      controlKeyState => 0+ $args{controlKeyState} || $HAS{controlKeyState}->(),
      buttons         => 0+ $args{buttons}         || $HAS{buttons}->(),
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
      $self->{where} = $HAS{where}->();
    }
    bless $self, $class;
    Hash::Util::lock_keys( %$self ) if STRICT;
    return $self;
  } #/ sub MouseEventType::new

  sub clone {    # $obj ()
    my ( $self ) = @_;
    assert ( @_ == 1 );
    assert ( blessed $self );
    my $class = ref $self || return;
    my $clone = bless { %$self }, $class;
    Hash::Util::lock_keys( %$clone ) if STRICT;
    $clone->{where} = $self->{where}->clone();
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
  use Scalar::Util qw( blessed );
  use Tie::Hash;

  our %HAS = (
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
  lock_hash( %HAS );

  use parent 'Tie::Hash';

  sub new {    # $obj (%args)
    my ( $class, %args ) = @_;
    assert ( $class and !ref $class );
    my $self = bless {}, $class;
    tie %$self, $class;
    map { $self->{$_} = $args{$_} }
      grep { exists $args{$_} }
        keys %HAS;
    return $self;
  }

  sub clone {    # $obj ()
    my ( $self ) = @_;
    assert ( @_ == 1 );
    assert ( blessed $self );
    my $class = ref $self || return;
    my $clone = bless {}, $class;
    tie %$clone, $class;
    map { $clone->{$_} = $self->{$_} } keys %HAS;
    return $clone;
  }

  sub TIEHASH  { bless \( my $data ), $_[0] }
  sub STORE    { $HAS{ $_[1] }->( $_[0], $_[2] ) }
  sub FETCH    { $HAS{ $_[1] }->( $_[0] ) }
  sub FIRSTKEY { my $a = scalar keys %HAS; each %HAS }
  sub NEXTKEY  { each %HAS }
  sub EXISTS   { exists $HAS{ $_[1] } }
  sub DELETE   { delete $HAS{ $_[1] } }  # raise an exception
  sub CLEAR    { %HAS = () }             # raise an exception
  sub SCALAR   { scalar keys %HAS }      # return number of elements (> 5.24)

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
  use Scalar::Util qw( blessed );
  use Tie::Hash;

  our %HAS = (
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
  lock_hash( %HAS );

  use parent 'Tie::Hash';

  sub new {    # $obj (%args)
    my ( $class, %args ) = @_;
    assert ( $class and !ref $class );
    my $self = bless {}, $class;
    tie %$self, $class;
    map { $self->{$_} = $args{$_} }
      grep { exists $args{$_} }
        keys %HAS;
    return $self;
  }

  sub clone {    # $obj ()
    my ( $self ) = @_;
    assert ( @_ == 1 );
    assert ( blessed $self );
    my $class = ref $self || return;
    my $clone = bless {}, $class;
    tie %$clone, $class;
    $clone->{keyCode}         = $self->{keyCode};
    $clone->{controlKeyState} = $self->{controlKeyState};
    return $clone;
  }

  sub TIEHASH  { bless [ CharScanType->new(), 0 ], $_[0] }
  sub STORE    { $HAS{ $_[1] }->( $_[0], $_[2] ) }
  sub FETCH    { $HAS{ $_[1] }->( $_[0] ) }
  sub FIRSTKEY { my $a = scalar keys %HAS; each %HAS }
  sub NEXTKEY  { each %HAS }
  sub EXISTS   { exists $HAS{ $_[1] } }
  sub DELETE   { delete $HAS{ $_[1] } }  # raise an exception
  sub CLEAR    { %HAS = () }             # raise an exception
  sub SCALAR   { scalar keys %HAS }      # return number of elements (> 5.24)

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
  use Scalar::Util qw(
    blessed
    weaken
  );
  use Tie::Hash;

  our %HAS = (
    command => sub {
      no warnings 'uninitialized';
      my ( $this, $cmd ) = @_;
      $this->[0] = 0+$cmd if @_ > 1;
      $this->[0];
    },
    infoPtr => sub {
      my ( $this, $info ) = @_;
      if ( @_ > 1 ) {
        $this->[1] = $info;
        weaken $this->[1] if ref $info;
      }
      $this->[1];
    },
    infoLong => sub {
      no warnings qw( uninitialized numeric );
      my ( $this, $info ) = @_;
      $this->[1] = 0+$info & 0xffff_ffff if @_ > 1;
      0+$this->[1] & 0xffff_ffff;
    },
    infoWord => sub {
      no warnings qw( uninitialized numeric );
      my ( $this, $info ) = @_;
      $this->[1] = 0+$info & 0xffff if @_ > 1;
      0+$this->[1] & 0xffff;
    },
    infoInt => sub {
      no warnings qw( uninitialized numeric );
      my ( $this, $info ) = @_;
      $this->[1] = 0+$info if @_ > 1;
      0+$this->[1];
    },
    infoByte => sub {
      no warnings qw( uninitialized numeric );
      my ( $this, $info ) = @_;
      $this->[1] = 0+$info & 0xff if @_ > 1;
      0+$this->[1] & 0xff;
    },
    infoChar => sub {
      no warnings qw( uninitialized numeric );
      my ( $this, $info ) = @_;
      $this->[1] = ord $_[1] if @_ > 1;
      chr( 0+$this->[1] );
    },
  );
  lock_hash( %HAS );

  use parent 'Tie::Hash';

  sub new {    # $obj (%args)
    my ( $class, %args ) = @_;
    assert ( $class and !ref $class );
    my $self = bless {}, $class;
    tie %$self, $class;
    map { $self->{$_} = $args{$_} }
      grep { exists $args{$_} }
        keys %HAS;
    return $self;
  } #/ sub new

  sub clone {    # $obj ()
    my ( $self ) = @_;
    assert ( @_ == 1 );
    assert ( blessed $self );
    my $class = ref $self || return;
    my $clone = bless {}, $class;
    tie %$clone, $class;
    $clone->{command} = $self->{command};
    if ( blessed $self->{infoPtr} && $self->{infoPtr}->can( 'clone' ) ) {
      $clone->{infoPtr} = $self->{infoPtr}->clone();
    }
    elsif ( ref $self->{infoPtr} ) {
      weaken( $clone->{infoPtr} = $self->{infoPtr} );
    }
    else {
      $clone->{infoPtr} = $self->{infoPtr};
    }
    return $clone;
  }

  sub TIEHASH  { bless [ 0, 0 ], $_[0] }
  sub STORE    { $HAS{ $_[1] }->( $_[0], $_[2] ) }
  sub FETCH    { $HAS{ $_[1] }->( $_[0] ) }
  sub FIRSTKEY { my $a = scalar keys %HAS; each %HAS }
  sub NEXTKEY  { each %HAS }
  sub EXISTS   { exists $HAS{ $_[1] } }
  sub DELETE   { delete $HAS{ $_[1] } }  # raise an exception
  sub CLEAR    { %HAS = () }             # raise an exception
  sub SCALAR   { scalar keys %HAS }      # return number of elements (> 5.24)

  $INC{"MessageEvent.pm"} = 1;
}

sub TEvent() { __PACKAGE__ }
sub new_TEvent { __PACKAGE__->from(@_) }

our %HAS = (
  what => sub {
    my ( $this, $what ) = @_;
    if ( @_ > 1 ) {
      assert ( looks_like_number $what );
      no warnings 'uninitialized';
      $what += evNothing;
      my $type = ref $this->[1];
      if ( ( $what & evMouse ) && $type !~ /mouse/i ) {
        @$this = ( $what, MouseEventType->new() );
      }
      elsif ( ( $what & evKeyboard ) && $type !~ /keyDown/i ) {
        @$this = ( $what, KeyDownEvent->new() );
      }
      elsif ( ( $what & evMessage ) && $type !~ /message/i ) {
        @$this = ( $what, MessageEvent->new() );
      }
      else {
        $this->[0] = $what;
      }
    }
    $this->[0];
  },
  mouse => sub {
    my ( $this, $mouse ) = @_;
    $this->[1] = $mouse if @_ > 1;
    my $type = ref $this->[1];
    $type =~ /mouse/i ? $this->[1] : undef;
  },
  keyDown => sub {
    my ( $this, $keyDown ) = @_;
    $this->[1] = $keyDown if @_ > 1;
    my $type = ref $this->[1];
    $type =~ /keyDown/i ? $this->[1] : undef;
  },
  message => sub {
    my ( $this, $message ) = @_;
    $this->[1] = $message if @_ > 1;
    my $type = ref $this->[1];
    $type =~ /message/i ? $this->[1] : undef;
  },
);
lock_hash( %HAS );

use parent 'Tie::Hash';

sub new {    # $obj (%args)
  no warnings 'uninitialized';
  my ( $class, %args ) = @_;
  assert ( $class and !ref $class );
  my $self = bless {}, $class;
  tie %$self, $class;
  my $this = tied %$self;
  assert ( !exists $args{what} or looks_like_number $args{what} );
  if ( $args{what} & evMouse ) {
    $this->[0] = $args{what},
    $this->[1] = MouseEventType->new(
      map { $_ => $args{mouse}{$_} }
        grep { exists $args{mouse}{$_} } 
          qw( where eventFlags controlKeyState buttons )
    );
  }
  elsif ( $args{what} & evKeyboard ) {
    $this->[0] = $args{what},
    $this->[1] = KeyDownEvent->new( 
      map { $_ => $args{keyDown}{$_} }
        grep { exists $args{keyDown}{$_} } 
          qw( keyCode charScan controlKeyState )
    );
  }
  elsif ( $args{what} & evMessage ) {
    $this->[0] = $args{what},
    $this->[1] = MessageEvent->new( 
      map { $_ => $args{message}{$_} }
        grep { exists $args{message}{$_} } 
          qw( command infoPtr infoLong infoWord infoInt infoByte infoChar )
    );
  }
  return $self;
} #/ sub new

sub from {    # $obj ()
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 0 );
  return $class->new();
}

sub dump {    # $str (|$maxDepth)
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  no warnings 'once';
  require Data::Dumper;
  local $Data::Dumper::Sortkeys = 1;
  local $Data::Dumper::Maxdepth = @_ ? shift : 3;
  my $str = Data::Dumper::Dumper $self;
  $str =~ s/(^|\s)\$VAR\d+\b/$1'$self'/g;
  return $str;
}

sub assign {    # $self ($event)
  my ( $self, $event ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( blessed $event );
  $self->{what} = $event->{what};
  if ( $event->{mouse} ) {
    $self->{mouse} = $event->{mouse}->clone();
  }
  elsif ( $event->{keyDown} ) {
    $self->{keyDown} = $event->{keyDown}->clone();
  }
  elsif ( $event->{message} ) {
    $self->{message} = $event->{message}->clone();
  }
  return $self;
}

sub clone {    # $obj ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  my $class = ref $self || return;
  my $clone = bless {}, $class;
  tie %$clone, $class;
  $clone->{what} = $self->{what};
  if ( $self->{mouse} ) {
    $clone->{mouse} = $self->{mouse}->clone();
  }
  elsif ( $self->{keyDown} ) {
    $clone->{keyDown} = $self->{keyDown}->clone();
  }
  elsif ( $self->{message} ) {
    $clone->{message} = $self->{message}->clone();
  }
  return $clone;
}

sub TIEHASH  { bless [ evNothing, undef ], $_[0] }
sub STORE    { $HAS{ $_[1] }->( $_[0], $_[2] ) }
sub FETCH    { $HAS{ $_[1] }->( $_[0] ) }
sub FIRSTKEY { my $a = scalar keys %HAS; each %HAS }
sub NEXTKEY  { each %HAS }
sub EXISTS   { exists $HAS{ $_[1] } }
sub DELETE   { delete $HAS{ $_[1] } }  # raise an exception
sub CLEAR    { %HAS = () }             # raise an exception
sub SCALAR   { scalar keys %HAS }      # return number of elements (> 5.24)

sub getMouseEvent {    # void ($self)
  assert ( blessed $_[0] );
  require TV::Drivers::EventQueue;
  TV::Drivers::EventQueue->getMouseEvent( $_[0] );
  return;
}

sub getKeyEvent {    # void ($self)
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  if ( THardwareInfo->getKeyEvent( $self ) ) {

    # Need to handle special case of Alt-Space, Ctrl-Ins, Shift-Ins,
    # Ctrl-Del, Shift-Del

    SWITCH: for ( $self->{keyDown}{keyCode} ) {
      $_ == ord(' ') and do {
        if ( $self->{keyDown}{controlKeyState} & kbAltShift ) {
          $self->{keyDown}{keyCode} = kbAltSpace;
        }
        last;
      };
      $_ == kbDel and do {
        if ( $self->{keyDown}{controlKeyState} & kbCtrlShift ) {
          $self->{keyDown}{keyCode} = kbCtrlDel;
        }
        elsif ( $self->{keyDown}{controlKeyState} & kbShift ) {
          $self->{keyDown}{keyCode} = kbShiftDel;
        }
        last;
      };
      $_ == kbIns and do {
        if ( $self->{keyDown}{controlKeyState} & kbCtrlShift ) {
          $self->{keyDown}{keyCode} = kbCtrlIns;
        }
        elsif ( $self->{keyDown}{controlKeyState} & kbShift ) {
          $self->{keyDown}{keyCode} = kbShiftIns;
        }
        last;
      };
    } #/ SWITCH: for ( $self->{keyDown}{...})
  } #/ if ( THardwareInfo->getKeyEvent...)
  else {
    $self->{what} = evNothing;
  }
  return;
} #/ sub getKeyEvent

1
