package TV::Gadgets::EventViewer;
# ABSTRACT: TEventViewer is a Terminal window for showing received TEvents.

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TEventViewer
  new_TEventViewer
);

require bytes;
use Carp ();
use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Encode qw( decode );
use Params::Check qw(
  check
  last_error
);
use Scalar::Util qw(
  blessed
  weaken
);

use TV::Drivers::Const qw( :evXXXX );
use TV::Gadgets::Const qw( cmFndEventView );
use TV::Gadgets::PrintConstants qw(
  printKeyCode
  printControlKeyState
  printEventCode
  printMouseButtonState
  printMouseWheelState
  printMouseEventFlags
);
use TV::TextView::Terminal;
use TV::Views::Const qw(
  sbHandleKeyboard
  sbVertical
  wnNoNumber
);
use TV::Views::Window;
use TV::toolkit;

sub TEventViewer() { __PACKAGE__ }
sub name() { 'TEventViewer' }
sub new_TEventViewer { __PACKAGE__->from(@_) }

extends TWindow;

# declare attributes
has stopped    => ( is => 'rw' );
has eventCount => ( is => 'rw' );
has bufSize    => ( is => 'rw' );
has interior   => ( is => 'rw' );
has scrollBar  => ( is => 'rw' );
has out        => ( is => 'rw' );

my $titles = [
  "Event Viewer", 
  "Event Viewer (Stopped)"
];

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  local $Params::Check::PRESERVE_CASE = 1;
  my $args1 = $class->SUPER::BUILDARGS( @_, title => '', number => wnNoNumber );
  my $args2 = STRICT ? check( {
    # 'required' arguments
    bufSize => { required => 1, defined => 1, allow => qr/^\d+$/ },
  } => { @_ } ) || Carp::confess( last_error ) : { @_ };
  return { %$args1, %$args2 };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  $self->{eventMask} |= evBroadcast;
  $self->init( $args->{bufSize} );
  return;
}

sub init {    # void ($bufSize)
  my ( $self, $bufSize ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  $self->{stopped} = 0;
  $self->{eventCount} = 0;
  $self->{bufSize} = $bufSize;
  $self->{title} = $titles->[ $self->{stopped} ? 1 : 0 ];
  $self->{scrollBar} = $self->standardScrollBar( sbVertical | sbHandleKeyboard );
  my $ostream = Symbol::gensym;
  $self->{interior} = tie *$ostream, TTerminal, (
    bounds      => do { local $_ = $self->getExtent(); $_->grow( -1, -1 ); $_ },
    hScrollBar => undef,
    vScrollBar => $self->{scrollBar},
    bufSize    => $self->{bufSize},
  );
  $self->insert( $self->{interior} );
  $self->{out} = $ostream;
  return;
} #/ sub init

sub from {    # $evntview ($bounds, aBufSize)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 2 );
  return $class->new( bounds => $_[0], bufSize => $_[1] );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  $self->{title} = undef;    # So that TWindow doesn't delete it.
  return;
}

sub toggle {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  $self->{stopped} = !$self->{stopped};
  $self->{title}   = $titles->[ $self->{stopped} ? 1 : 0 ];
  $self->{frame}->drawView() if $self->{frame};
  return;
}

sub print {    # void ($event)
  my ( $self, $ev ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( blessed $ev );
  if ( $ev->{what} != evNothing && !$self->{stopped} && $self->{out} ) {
    local *OUT = $self->{out};
    $self->lock();
    print OUT "Received event #", ++$self->{eventCount}, "\n";
    $self->printEvent( \*OUT, $ev );
    tied(*OUT)->flush();
    $self->unlock();
  }
  return;
} #/ sub print

sub shutDown {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  $self->{out}       = undef;
  $self->{interior}  = undef;
  $self->{scrollBar} = undef;
  $self->SUPER::shutDown();
  return;
}

sub handleEvent {    # void ($event)
  my ( $self, $ev ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( blessed $ev );
  $self->SUPER::handleEvent( $ev );
  if ( $ev->{what} == evBroadcast 
    && $ev->{message}{command} == cmFndEventView
  ) {
    $self->clearEvent( $ev );
  }
  return;
}

my $printConstants = sub {    # void ($value, $doPrint)
  my ( $value, $doPrint ) = @_;
  printf "0x%04X", $value;
  my $buf = '';
  eval {
    open my $os, '>', \$buf;
    $os->$doPrint( $value );
    close $os;
  };
  if ( !@! && $buf !~ /^0/ ) {
    print " (", $buf, ")";
  }
  return;
};

sub printEvent {    # void ($out, $ev)
  my ( $self, $out, $ev ) = @_;
  assert ( @_ == 3 );
  assert ( blessed $self );
  assert ( ref $out );
  assert ( blessed $ev );

  my $current = select $out;
  print "TEvent {\n", 
        "  .what = ";
  &$printConstants( $ev->{what}, \&printEventCode );
  print ",\n";

  if ( $ev->{what} & evMouse ) {
    print "  .mouse = MouseEventType {\n",
          "    .where = TPoint {\n",
          "       .x = ", $ev->{mouse}{where}{x}, "\n",
          "       .y = ", $ev->{mouse}{where}{y}, "\n",
          "    },\n",
          "    .eventFlags = ";
    &$printConstants( $ev->{mouse}{eventFlags}, \&printMouseEventFlags );
    print ",\n",
          "    .controlKeyState = ";
    &$printConstants( $ev->{mouse}{controlKeyState},
      \&printControlKeyState );
    print ",\n",
          "    .buttons = ";
    &$printConstants( $ev->{mouse}{buttons}, \&printMouseButtonState );
    # TODO: TEvent->{mouse}{wheel} support
    # print ",\n", 
    #       "    .wheel = ";
    # &$printConstants( $ev->{mouse}{wheel}, \&printMouseWheelState );
    print "\n  }\n";
  } #/ if ( $ev->{what} & evMouse)

  if ( $ev->{what} & evKeyboard ) {
    my $charCode = $ev->{keyDown}{charScan}{charCode};
    print "  .keyDown = KeyDownEvent {\n",
          "    .keyCode = ";
    &$printConstants( $ev->{keyDown}{keyCode}, \&printKeyCode );
    print ",\n", 
          "    .charScan = CharScanType {\n",
          "      .charCode = ", $charCode;
    print " ('", chr $charCode, "')" if $charCode;
    print ",\n",
          "      .scanCode = ", $ev->{keyDown}{charScan}{scanCode}, 
          "\n", 
          "    },\n",
          "    .controlKeyState = ";
    &$printConstants( $ev->{keyDown}{controlKeyState},
      \&printControlKeyState );
    print ",\n";
    print "    .text = {";
    # TODO: The field {charScan}{charCode} contains characters from the CP437 
    # code page in the original. For full Unicode support, the two new fields 
    # 'text' and 'textLength' should be used (L</SEE ALSO>).
    my @text = $ev->{keyDown}{charScan}{charCode} ? 
      unpack( 'C*', bytes::substr(
        decode( 'cp437', chr $ev->{keyDown}{charScan}{charCode} ),
          0 )) : ();
    my $textLength = @text;
    print join(', ', map { sprintf "0x%02X", $_ } @text );
    print "},\n",
          "    .textLength = ", $textLength, "\n", 
          "  }\n";
  } #/ if ( $ev->{what} & evKeyboard)

  if ( $ev->{what} & evCommand ) {
    print "  .message = MessageEvent {\n",
          "    .command = ", $ev->{message}{command}, ",\n", 
          "    .infoPtr = ", $ev->{message}{infoPtr} // 'undef', "\n", 
          "  }\n";
  }
  print( "}\n" );
  select $current;
  return;
} #/ sub printEvent

1

__END__

=head1 NAME

TV::Gadgets::EventViewer - A Terminal window for showing received TEvents.

=head1 DESCRIPTION

C<TEventViewer> is a Terminal window displaying the attributes of 
C<TEvents> received by the application.

This code base was taken from the framework 
I<"A modern port of Turbo Vision 2.0"> and is inspired by TTYWindow from 
Daniel Ambrose.

=head1 METHODS

=head2 new

  my $evntview = TEventViewer->new(%args);

Creates a new C<TEventViewer> instance with the given arguments.

=over

=item bounds

The bounds of the scroller (I<TRect>).

=item bufSize

Defines the buffer size (I<Int>).

=back

=head2 new_TEventViewer

 my $evntview = new_TEventViewer($bounds, $bufSize);

Factory constructor for creating a new event viewer object.

=head1 SEE ALSO

I<evntview.h>, I<evntview.cpp>, 
L<Reading Unicode input|https://github.com/magiblot/tvision/blob/423aeb568a181ffebb3695859654385950588a93/README.md#reading-unicode-input>

=head1 AUTHORS

=over

=item Turbo Vision Development Team

=item J. Schneider <brickpool@cpan.org>

=back

=head1 CONTRIBUTORS

=over

=item magiblot <magiblot@hotmail.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2019-2026 the L</AUTHORS> and L</CONTRIBUTORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution).

=cut
