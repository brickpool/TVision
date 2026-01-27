package TV::Views::Window;
# ABSTRACT: A base class for managing windows in Turbo Vision 2.0.

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TWindow
  new_TWindow
);

use Carp ();
use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Params::Check qw(
  check
  last_error
);
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::App::Program;
use TV::Drivers::Const qw(
  :evXXXX
  :kbXXXX
);
use TV::Objects::Point;
use TV::Objects::Rect;
use TV::Views::Const qw(
  :cmXXXX
  :cpXXXX
  :gfXXXX
  :ofXXXX
  :sbXXXX
  :sfXXXX
  :wfXXXX
  wpBlueWindow
);
use TV::Views::CommandSet;
use TV::Views::Frame;
use TV::Views::Group;
use TV::Views::Palette;
use TV::Views::ScrollBar;
use TV::Views::WindowInit;
use TV::toolkit;

sub TWindow() { __PACKAGE__ }
sub name() { 'TWindow' }
sub new_TWindow { __PACKAGE__->from(@_) }

extends ( TGroup, TWindowInit );

# declare global variables
our $minWinSize = TPoint->new( x => 16, y => 6 );

# import global variables
use vars qw(
  $appPalette
);
{
  no strict 'refs';
  *appPalette = \${ TProgram . '::appPalette' };
}

# declare attributes
has flags    => ( is => 'rw' );
has zoomRect => ( is => 'rw' );
has number   => ( is => 'rw' );
has palette  => ( is => 'rw' );
has frame    => ( is => 'rw' );
has title    => ( is => 'rw' );

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  local $Params::Check::PRESERVE_CASE = 1;
  my $args1 = TGroup->BUILDARGS( @_ );
  my $args2 = check( {
    # set 'default' values, init_args => undef
    flags => { 
      default     => wfMove | wfGrow | wfClose | wfZoom, 
      no_override => 1,
    },
    palette => { default => wpBlueWindow, no_override => 1 },
    # 'required' arguments
    number => { required => 1, defined => 1, allow => qr/^\d+$/ },
    title  => { required => 1, defined => 1, default => '', strict_type => 1 },
  } => { @_ } ) || Carp::confess( last_error );
  my $args3 = TWindowInit->BUILDARGS( cFrame => $class->can( 'initFrame' ) );
  return { %$args1, %$args2, %$args3 };
}

sub BUILD {    # void (|\%args)
  my $self = shift;
  assert ( blessed $self );
  $self->{zoomRect} = $self->getBounds();

  $self->{state}   |= sfShadow;
  $self->{options} |= ofSelectable | ofTopSelect;
  $self->{growMode} = gfGrowAll | gfGrowRel;

  if ( $self->{createFrame}
    && ( $self->{frame} = $self->createFrame( $self->getExtent() ) )
  ) {
    $self->insert( $self->{frame} );
  }
  return;
} #/ sub new

sub from {    # $obj ($bounds, $aTitle, $aNumber)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 3 );
  return $class->new( bounds => $_[0], title => $_[1], number => $_[2] );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  $self->{title} = undef;
  return;
}

sub close {    # void ()
  alias: for my $self ( $_[0] ) {    # Maybe we are destroying ourselves
  assert ( @_ == 1 );
  assert ( blessed $self );
  if ( $self->valid( cmClose ) ) {
    # so we don't try to use the frame after it's been deleted
    $self->{frame} = undef;
    $self->destroy( $self );
  }
  return;
  } #/ alias
}

my ( $blue, $cyan, $gray, @palettes );
sub getPalette {    # $palette ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  $blue ||= TPalette->new(
    data => cpBlueWindow,
    size => length( cpBlueWindow ) 
  );
  $cyan ||= TPalette->new( 
    data => cpCyanWindow,
    size => length( cpCyanWindow ) 
  );
  $gray ||= TPalette->new( 
    data => cpGrayWindow,
    size => length( cpGrayWindow ) 
  );
  @palettes = ( $blue, $cyan, $gray ) unless @palettes;
  return $palettes[$appPalette]->clone();
} #/ sub getPalette

sub getTitle {    # $str ($maxSize)
  my ( $self, $maxSize ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( looks_like_number $maxSize );
  return $self->{title};
}

sub handleEvent {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( blessed $event );
  my $limits = TRect->new();
  my ( $min, $max ) = ( TPoint->new(), TPoint->new() );

  $self->SUPER::handleEvent( $event );
  if ( $event->{what} == evCommand ) {
    SWITCH: for ( $event->{message}{command} ) {
      cmResize == $_ and do {
        if ( $self->{flags} & ( wfMove | wfGrow ) ) {
          $limits = $self->{owner}->getExtent();
          $self->sizeLimits( $min, $max );
          $self->dragView( $event, 
            $self->{dragMode} | ( $self->{flags} & ( wfMove | wfGrow ) ), 
            $limits, $min, $max
          );
          $self->clearEvent( $event );
        }
        last;
      };
      cmClose == $_ and do {
        no warnings 'uninitialized';
        if ( ( $self->{flags} & wfClose )
          && ( !$event->{message}{infoPtr}
            ||  $event->{message}{infoPtr} == $self
          ) 
        ) {
          $self->clearEvent( $event );
          if ( !( $self->{state} & sfModal ) ) {
            $self->close();
          }
          else {
            $event->{what} = evCommand;
            $event->{message}{command} = cmCancel;
            $self->putEvent( $event );
            $self->clearEvent( $event );
          }
        } #/ if ( $self->{flags} & ...)
        last;
      };
      cmZoom == $_ and do {
        no warnings 'uninitialized';
        if ( ( $self->{flags} & wfZoom )
          && ( !$event->{message}{infoPtr} 
            ||  $event->{message}{infoPtr} == $self
          )
        ) {
          $self->zoom();
          $self->clearEvent( $event );
        }
        last;
      };
    }
  }
  elsif ( $event->{what} == evKeyDown ) {
    SWITCH: for ( $event->{keyDown}{keyCode} ) {
      kbTab == $_ and do {
        $self->focusNext( !!0 );
        $self->clearEvent( $event );
        last;
      };
      kbShiftTab == $_ and do {
        $self->focusNext( !!1 );
        $self->clearEvent( $event );
        last;
      };
    }
  } #/ elsif ( $event->{what} ==...)
  elsif ( $event->{what} == evBroadcast
    && $event->{message}{command} == cmSelectWindowNum
    && $event->{message}{infoInt} == $self->{number}
    && ( $self->{options} & ofSelectable )
  ) {
    $self->select();
    $self->clearEvent( $event );
  }
  return;
} #/ sub handleEvent

sub initFrame {    # $frame ($r)
  my ( $class, $r ) = @_;
  assert ( @_ == 2 );
  assert ( $class );
  assert ( ref $r );
  return TFrame->new( bounds => $r );
}

sub setState {    # void ($aState, $enable)
  my ( $self, $aState, $enable ) = @_;
  assert ( @_ == 3 );
  assert ( blessed $self );
  assert ( looks_like_number $aState );
  assert ( !defined $enable or !ref $enable );
  my $windowCommands = TCommandSet->new();

  $self->SUPER::setState( $aState, $enable );
  if ( $aState & sfSelected ) {
    $self->setState( sfActive, $enable );
    if ( $self->{frame} ) {
      $self->{frame}->setState( sfActive, $enable );
    }
    $windowCommands += cmNext;
    $windowCommands += cmPrev;
    if ( $self->{flags} & ( wfGrow | wfMove ) ) {
      $windowCommands += cmResize;
    }
    if ( $self->{flags} & wfClose ) {
      $windowCommands += cmClose;
    }
    if ( $self->{flags} & wfZoom ) {
      $windowCommands += cmZoom;
    }
    if ( $enable ) {
      $self->enableCommands( $windowCommands );
    }
    else {
      $self->disableCommands( $windowCommands );
    }
  } #/ if ( $aState & sfSelected)
  return;
} #/ sub setState

sub sizeLimits {    # void ($min, $max)
  my ( $self, undef, undef ) = @_;
  alias: for my $min ( $_[1] ) {
  alias: for my $max ( $_[2] ) {
  assert ( @_ == 3 );
  assert ( blessed $self );
  assert ( blessed $min );
  assert ( blessed $max );
  $self->SUPER::sizeLimits( $min, $max );
  $min = $minWinSize->clone();
  return;
  }} #/ alias:
}

sub standardScrollBar {    # $scrollBar ($aOptions)
  my ( $self, $aOptions ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( looks_like_number $aOptions );
  my $r = $self->getExtent();
  if ( $aOptions & sbVertical ) {
    $r = TRect->new(
      ax => $r->{b}{x} - 1, ay => $r->{a}{y} + 1,
      bx => $r->{b}{x},     by => $r->{b}{y} - 1,
    );
  }
  else {
    $r = TRect->new(
      ax => $r->{a}{x} + 2, ay => $r->{b}{y} - 1, 
      bx => $r->{b}{x} - 2, by => $r->{b}{y},
    );
  }

  my $s = TScrollBar->new( bounds => $r );
  $self->insert( $s );
  if ( $aOptions & sbHandleKeyboard ) {
    $s->{options} |= ofPostProcess;
  }
  return $s;
} #/ sub standardScrollBar

sub zoom {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  my ( $minSize, $maxSize ) = ( TPoint->new(), TPoint->new() );
  $self->sizeLimits( $minSize, $maxSize );
  if ( $self->{size} != $maxSize ) {
    $self->{zoomRect} = $self->getBounds();
    my $r = TRect->new( 
      ax => 0, ay => 0, bx => $maxSize->{x}, by => $maxSize->{y}
    );
    $self->locate( $r );
  }
  else {
    $self->locate( $self->{zoomRect} );
  }
  return;
} #/ sub zoom

sub shutDown {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  $self->{frame} = undef;
  $self->SUPER::shutDown();
  return;
}

1

__END__

=pod

=head1 NAME

TV::Views::Window - a base class for managing windows in Turbo Vision 2.0.

=head1 SYNOPSIS

  use TV::Views;

  my $window = TWindow->new( bounds => $r, title => 'Title', number => 0 );

=head1 DESCRIPTION

The TWindow class is used to manage windows and their components in a Turbo 
Vision application. It provides methods to handle window operations such as 
opening, closing, and resizing. This class is essential for creating and 
managing user interface windows on the desktop.

=head1 ATTRIBUTES

=over

=item flags

Stores the state flags of the window. (Int)

=item frame

A reference to the frame of the window. (TFrame)

=item number

The unique identifier number of the window. (Int)

=item palette

The color palette used by the window. (TPalette)

=item title

The title of the window. (Str)

=item zoomRect

The rectangle defining the zoomed state of the window. (TRect)

=back

=head1 METHODS

=head2 new

  my $obj = TWindow->new(%args);

Creates a new TWindow object.

=over

=item bounds

The bounds of the window. (TRect)

=item title

The title of the window. (Str)

=item number

The unique identifier number of the window. (Int)

=back

=head2 DEMOLISH

  $self->DEMOLISH($in_global_destruction);

Destroys the window and releases its resources.

=head2 close

  $self->close();

Closes the window.

=head2 from

  my $obj = $self->from($bounds, $aTitle, $aNumber);

Creates a TWindow object from the specified bounds, title, and number.

=head2 getPalette

  my $palette = $self->getPalette();

Returns the color palette of the window.

=head2 getTitle

  my $str = $self->getTitle($maxSize);

Returns the title of the window, truncated to the specified maximum size.

=head2 handleEvent

  $self->handleEvent($event);

Handles an event sent to the window.

=head2 initFrame

  my $frame = $self->initFrame($r);

Initializes the frame of the window.

=head2 setState

  $self->setState($aState, $enable);

Sets the state of the window to the specified value.

=head2 shutDown

  $self->shutDown();

Shuts down the window and releases its resources.

=head2 sizeLimits

  $self->sizeLimits($min, $max);

Sets the minimum and maximum size limits of the window.

=head2 standardScrollBar

  my $scrollBar = $self->standardScrollBar($aOptions);

Creates a standard scroll bar for the window with the specified options.

=head2 zoom

  $self->zoom();

Zooms the window to its maximum or previous size.

=head1 AUTHORS

=over

=item Turbo Vision Development Team

=item J. Schneider <brickpool@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution). This documentation is provided under the same terms 
as the Turbo Vision library itself.

=cut
