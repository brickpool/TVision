package TV::Dialogs::History;
# ABSTRACT: A TWindow-based history browser for TVision input controls

use 5.010;
use strict;
use warnings;
use utf8;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  THistory
  new_THistory
);

use PerlX::Assert::PP;
use TV::toolkit;
use TV::toolkit::Params qw( signature );
use TV::toolkit::Types qw(
  is_Object
  :types
);

use TV::Dialogs::Const qw( 
  cmRecordHistory
  cpHistory
);
use TV::Dialogs::HistoryViewer::HistList qw( historyAdd );
use TV::Dialogs::HistoryWindow;
use TV::Dialogs::InputLine;
use TV::Drivers::Const qw(
  :evXXXX
  kbDown
);
use TV::Drivers::Util qw( ctrlToArrow );
use TV::Objects::Rect;
use TV::Views::Const qw(
  cmOK
  cmReleasedFocus
  ofPostProcess
  sfFocused
);
use TV::Views::DrawBuffer;
use TV::Views::Palette;
use TV::Views::View;

sub THistory() { __PACKAGE__ }
sub name() { 'THistory' }
sub new_THistory { __PACKAGE__->from(@_) }

extends TView;

# declare global variables
our $icon = "\xDE~\x19~\xDD";    # cp437: "▐~↓~▌"

# protected attributes
has link      => ( is => 'ro', default => sub { die 'required' } );
has historyId => ( is => 'ro', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      bounds    => Object,
      link      => Object,            { alias => 'aLink' },
      historyId => PositiveOrZeroInt, { alias => 'aHistoryId' },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return $args;
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{options}   |= ofPostProcess;
  $self->{eventMask} |= evBroadcast;
  return;
}

sub from {    # $obj ($bounds, $aLink, $aHistoryId)
  state $sig = signature(
    method => 1,
    pos    => [Object, Object, PositiveOrZeroInt],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], link => $args[1], 
    historyId => $args[2] );
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $b = TDrawBuffer->new();
  $b->moveCStr( 0, $icon, $self->getColor( 0x0102 ) );
  $self->writeLine( 0, 0, $self->{size}{x}, $self->{size}{y}, $b );
  return;
}

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cpHistory,
    size => length( cpHistory ),
  );
  return $palette->clone();
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
 
  my $historyWindow;
  my ( $r, $p );
  my $c;

  $self->SUPER::handleEvent( $event );
  if ( $event->{what} == evMouseDown
    || ( $event->{what} == evKeyDown
      && ctrlToArrow( $event->{keyDown}{keyCode} ) == kbDown
      && ( $self->{link}{state} & sfFocused ) )
  ) {
    if ( !$self->{link}->focus() ) {
      $self->clearEvent( $event );
      return;
    }
    $self->recordHistory( $self->{link}{data} );
    $r = $self->{link}->getBounds();
    $r->{a}{x}--;
    $r->{b}{x}++;
    $r->{b}{y} += 7;
    $r->{a}{y}--;
    $p = $self->{owner}->getExtent();
    $r->intersect( $p );
    $r->{b}{y}--;
    $historyWindow = $self->initHistoryWindow( $r );

    if ( $historyWindow != 0 ) {
      $c = $self->{owner}->execView( $historyWindow );
      if ( $c == cmOK ) {
        my $rslt;
        $historyWindow->getSelection( \$rslt );
        $self->{link}{data} = substr( $rslt, 0, $self->{link}{maxLen} );
        $self->{link}->selectAll( !!1 );
        $self->{link}->drawView();
      }
      $self->destroy( $historyWindow );
    } #/ if ( $historyWindow !=...)
    $self->clearEvent( $event );
  }
  else {
    if ( $event->{what} == evBroadcast ) {
      no warnings 'uninitialized';
      if ( ( $event->{message}{command} == cmReleasedFocus
          && $event->{message}{infoPtr} == $self->{link} )
        || $event->{message}{command} == cmRecordHistory
      ) {
        $self->recordHistory( $self->{link}{data} );
      } #/ if ( ( $event->{message...}))
    } #/ if ( $event->{what} ==...)
  }
  return;
}

sub initHistoryWindow {    # $historyWindow ($bounds)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $bounds ) = $sig->( @_ );
  my $p = THistoryWindow->new(
    bounds    => $bounds,
    historyId => $self->{historyId},
  );
  $p->{helpCtx} = $self->{link}{helpCtx};
  return $p;
}

sub recordHistory {    # void ($s)
  state $sig = signature(
    method => Object,
    pos    => [Str],
  );
  my ( $self, $s ) = $sig->( @_ );
  historyAdd( $self->{historyId}, $s );
  return;
}

sub shutDown {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->{link} = undef;
  $self->SUPER::shutDown();
  return;
}

1
