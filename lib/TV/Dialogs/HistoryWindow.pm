package TV::Dialogs::HistoryWindow;
# ABSTRACT: Window component showing and managing history list items

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  THistoryWindow
  new_THistoryWindow
);

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

use TV::Dialogs::Const qw( cpHistoryWindow );
use TV::Dialogs::HistInit;
use TV::Dialogs::HistoryViewer;
use TV::Views::Const qw(
  sbHandleKeyboard
  sbHorizontal
  sbVertical
  wfClose
  wnNoNumber
);
use TV::Views::Palette;
use TV::Views::Window;
use TV::toolkit;

sub THistoryWindow() { __PACKAGE__ }
sub new_THistoryWindow { __PACKAGE__->from(@_) }

extends ( TWindow, THistInit );

# declare attributes
has viewer => ( is => 'ro' );

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  local $Params::Check::PRESERVE_CASE = 1;
  my $args1 = TWindow->BUILDARGS( @_, title => '', number => wnNoNumber );
  my $args2 = THistInit->BUILDARGS( cListViewer => $class->can('initViewer') );
  my $args3 = check( {
    # additional 'required' arguments
    historyId => { required => 1, defined => 1, allow => qr/^\d+$/ },
  } => { @_ } ) || Carp::confess( last_error );
  return { %$args1, %$args2, %$args3 };
}

sub BUILD {    # void (|\%args)
  my ( $self, $args ) = @_;
  assert ( blessed $self );
  $self->{flags} = wfClose;
  if ( $self->{createListViewer} ) {
    $self->{viewer} = $self->createListViewer( $self->getExtent(), $self, 
      $args->{historyId} );
    $self->insert( $self->{viewer} ) if $self->{viewer};
  }
  return;
}

sub from {    # $obj ($bounds, $historyId)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 2 );
  return $class->new( bounds => $_[0], historyId => $_[1] );
}

my $palette;
sub getPalette {    # $palette ()
  my ( $self ) = @_;
  assert { @_ == 1 };
  assert { blessed $self };
  $palette ||= TPalette->new(
    data => cpHistoryWindow, 
    size => length( cpHistoryWindow ),
  );
  return $palette->clone();
}

sub getSelection {    # void (\$dest)
  my ( $self, $dest_ref ) = @_;
  assert { @_ == 2 };
  assert { blessed $self };
  assert { ref $dest_ref and !readonly $$dest_ref };
  $self->{viewer}->getText( $dest_ref, $self->{viewer}{focused}, 255 );
  return;
}

sub initViewer {    # $listViewer ($r, $win, $historyId)
  my ( $class, $r, $win, $historyId ) = @_;
  assert { @_ == 4 };
  assert { $class and !ref $class };
  assert { ref $r };
  assert { blessed $win };
  assert { looks_like_number $historyId };
  $r->grow( -1, -1 );
  return THistoryViewer->new(
    bounds     => $r,
    hScrollBar => $win->standardScrollBar( sbHorizontal | sbHandleKeyboard ),
    vScrollBar => $win->standardScrollBar( sbVertical | sbHandleKeyboard ),
    historyId  => $historyId,
  );
} #/ sub initViewer

1
