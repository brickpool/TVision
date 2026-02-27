package TV::Dialogs::History;
# ABSTRACT: A TWindow-based history browser for TVision input controls

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  THistory
  new_THistory
);

use Carp ();
use PerlX::Assert::PP;
use Params::Check qw(
  check
  last_error
);
use Scalar::Util qw(
  blessed
  looks_like_number
);
use utf8;

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
use TV::toolkit;

sub THistory() { __PACKAGE__ }
sub name() { 'THistory' }
sub new_THistory { __PACKAGE__->from(@_) }

extends TView;

# declare global variables
our $icon = "\xDE~\x19~\xDD";    # cp437: "▐~↓~▌"

# declare attributes
has link      => ( is => 'ro' );
has historyId => ( is => 'ro' );

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert { $class and !ref $class };
  local $Params::Check::PRESERVE_CASE = 1;
  my $args1 = $class->SUPER::BUILDARGS( @_ );
  my $args2 = check( {
    # 'required' attributes
    link      => { required => 1, allow => sub { blessed $_[0] } },
    historyId => { required => 1, defined => 1, allow => qr/^\d+$/ },
  } => { @_ } ) || Carp::confess( last_error );
  return { %$args1, %$args2 };
}

sub BUILD {    # void (|\%args)
  my $self = shift;
  assert { blessed $self };
  $self->{options}   |= ofPostProcess;
  $self->{eventMask} |= evBroadcast;
  return;
}

sub from {    # $obj ($bounds, $aLink, $aHistoryId)
  my $class = shift;
  assert { $class and !ref $class };
  assert { @_ == 3 };
  return $class->new( bounds => $_[0], link => $_[1], historyId => $_[2] );
}

sub draw {    # void ()
  my ( $self ) = @_;
  assert { @_ == 1 };
  assert { blessed $self };
  my $b = TDrawBuffer->new();
  $b->moveCStr( 0, $icon, $self->getColor( 0x0102 ) );
  $self->writeLine( 0, 0, $self->{size}{x}, $self->{size}{y}, $b );
  return;
}

my $palette;
sub getPalette {    # $palette ()
  my ( $self ) = @_;
  assert { @_ == 1 };
  assert { blessed $self };
  $palette ||= TPalette->new( data => cpHistory, size => length( cpHistory ) );
  return $palette->clone();
}

sub handleEvent {    # void ($event)
  my ( $self, $event ) = @_;
  assert { @_ == 2 };
  assert { blessed $self };
  assert { blessed $event };
 
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
  my ( $self, $bounds ) = @_;
  assert { @_ == 2 };
  assert { blessed $self };
  assert { ref $bounds };
  my $p = THistoryWindow->new(
    bounds    => $bounds,
    historyId => $self->{historyId},
  );
  $p->{helpCtx} = $self->{link}{helpCtx};
  return $p;
}

sub recordHistory {    # void ($s)
  my ( $self, $s ) = @_;
  assert { @_ == 2 };
  assert { blessed $self };
  assert { defined $s and !ref $s };
  historyAdd( $self->{historyId}, $s );
  return;
}

sub shutDown {    # void ()
  my ( $self ) = @_;
  assert { @_ == 1 };
  assert { blessed $self };
  $self->{link} = undef;
  $self->SUPER::shutDown();
  return;
}

1
