package TV::Dialogs::HistoryViewer;
# ABSTRACT: THistoryViewer displays and manages input history in dialog boxes

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  THistoryViewer
  new_THistoryViewer
);

use Carp ();
use List::Util qw( max );
use PerlX::Assert::PP;
use Params::Check qw(
  check
  last_error
);
use Scalar::Util qw(
  blessed
  looks_like_number
  readonly
);

use TV::Const qw( EOS );
use TV::Dialogs::Const qw( cpHistoryViewer );
use TV::Dialogs::HistoryViewer::HistList qw(
  historyCount
  historyStr
);
use TV::Drivers::Const qw(
  :evXXXX
  kbEnter
  kbEsc
  meDoubleClick
);
use TV::Views::Const qw(
  cmCancel
  cmOK
);
use TV::Views::ListViewer;
use TV::Views::Palette;
use TV::toolkit;

sub THistoryViewer() { __PACKAGE__ }
sub new_THistoryViewer { __PACKAGE__->from(@_) }

extends TListViewer;

# declare attributes
has historyId => ( is => 'ro' );

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert { $class and !ref $class };
  local $Params::Check::PRESERVE_CASE = 1;
  my $args1 = $class->SUPER::BUILDARGS( @_, numCols => 1 );
  my $args2 = check( {
    # 'required' arguments
    hScrollBar => { required => 1, allow => sub { blessed $_[0] } },
    vScrollBar => { required => 1, allow => sub { blessed $_[0] } },
    historyId  => { required => 1, defined => 1, allow => qr/^\d+$/ },
  } => { @_ } ) || Carp::confess( last_error );
  return { %$args1, %$args2 };
}

sub BUILD {    # void (|\%args)
  my $self = shift;
  assert { blessed $self };
  $self->setRange( historyCount( $self->{historyId} ) );
  $self->focusItem( 1 ) 
    if $self->{range} > 1;
  $self->{hScrollBar}->setRange(
    0, 
    $self->historyWidth() - $self->{size}{x} + 3
  );
  return;
}

sub from {    # $obj ($bounds, $aHScrollBar, $aVScrollBar, $aHistoryId)
  my $class = shift;
  assert { $class and !ref $class };
  assert { @_ == 4 };
  return $class->new( bounds => $_[0], hScrollBar => $_[2], vScrollBar => $_[3], 
    historyId => $_[4] );
}

my $palette;
sub getPalette {    # $palette ()
  my ( $self ) = @_;
  assert { @_ == 1 };
  assert { blessed $self };
  $palette ||= TPalette->new(
    data => cpHistoryViewer, 
    size => length( cpHistoryViewer ),
  );
  return $palette->clone();
}

sub getText {    # void (\$dest, $item, $maxChars)
  my ( $self, $dest_ref, $item, $maxChars ) = @_;
  assert { @_ == 4 };
  assert { blessed $self };
  assert { ref $dest_ref and !readonly $$dest_ref };
  assert { looks_like_number $item };
  assert { looks_like_number $maxChars };
  alias: for my $dest ( $$dest_ref ) {
  my $str = historyStr( $self->{historyId}, $item );
  $dest = $str ? substr( $str, 0, $maxChars ) : EOS;
  return;
  } #/ alias: for my $dest ( $$dest_ref )
}

sub handleEvent {    # void ($event)
  no warnings 'uninitialized';
  my ( $self, $event ) = @_;
  assert { @_ == 2 };
  assert { blessed $self };
  assert { blessed $event };
  if ( ( $event->{what} == evMouseDown 
      && ( $event->{mouse}{eventFlags} & meDoubleClick ) )
    || ( $event->{what} == evKeyDown 
      && $event->{keyDown}{keyCode} == kbEnter )
  ) {
    $self->endModal( cmOK );
    $self->clearEvent( $event );
  }
  elsif (
      ( $event->{what} == evKeyDown 
        && $event->{keyDown}{keyCode} == kbEsc )
    || ( $event->{what} == evCommand 
        && $event->{message}{command} == cmCancel )
  ) {
    $self->endModal( cmCancel );
    $self->clearEvent( $event );
  }
  else {
    $self->SUPER::handleEvent( $event );
  }
  return;
}

sub historyWidth {    # $width ()
  my ( $self ) = @_;
  assert { @_ == 1 };
  assert { blessed $self };
  my $width = 0;
  my $count = historyCount( $self->{historyId} );
  for ( my $i = 0 ; $i < $count ; $i++ ) {
    my $T = length( historyStr( $self->{historyId}, $i ) );
    $width = max( $width, $T );
  }
   return $width;
}

1
