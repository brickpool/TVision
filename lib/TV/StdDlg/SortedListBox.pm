package TV::StdDlg::SortedListBox;
# ABSTRACT: TListBox subclass providing automatic item sorting

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT = qw(
  TSortedListBox
  new_TSortedListBox
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

use TV::Const qw( EOS );
use TV::Dialogs::ListBox;
use TV::Drivers::Const qw(
  :evXXXX
  kbBack
);
use TV::Objects::SortedCollection;
use TV::Views::Const qw( cmReleasedFocus );
use TV::toolkit;

sub TSortedListBox() { __PACKAGE__ }
sub name() { 'TSortedListBox' }
sub new_TSortedListBox { __PACKAGE__->from( @_ ) }

extends TListBox;

# declare attributes
has shiftState => ( is => 'ro' );
has searchPos  => ( is => 'bare' );

my $equal = sub {    # $bool ($s1, $s2, $count)
  my ( $s1, $s2, $count ) = @_;
  return lc( substr( $s1, 0, $count ) ) eq lc( substr( $s2, 0, $count ) );
};

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert { $class and !ref $class };
  local $Params::Check::PRESERVE_CASE = 1;
  my $args1 = $class->SUPER::BUILDARGS( @_ );
  my $args2 = check( {
    # set 'default' value, init_args => undef
    searchPos  => { default => -1, no_override => 1 },
    shiftState => { default => 0,  no_override => 1 },
  } => { @_ } ) || Carp::confess( last_error );
  return { %$args1, %$args2 };
}

sub BUILD {    # void (|\%args)
  my $self = shift;
  assert { blessed $self };
  $self->showCursor();
  $self->setCursor( 1, 0 );
  return;
}

sub handleEvent {    # void ($event)
  my ( $self, $event ) = @_;
  assert { @_ == 2 };
  assert { blessed $self };
  assert { blessed $event };

  my ( $curString, $newString );
  my $k;
  my $value;
  my ( $oldPos, $oldValue );

  $oldValue = $self->{focused};
  $self->SUPER::handleEvent( $event );
  if ( $oldValue != $self->{focused}
    || ( $event->{what} == evBroadcast
      && $event->{message}{command} == cmReleasedFocus )
  ) {
    $self->{searchPos} = -1;
  }
  if ( $event->{what} == evKeyDown ) {
    if ( $event->{keyDown}{charScan}{charCode} ) {
      $value = $self->{focused};
      if ( $value < $self->{range} ) {
        $self->getText( \$curString, $value, 255 );
      }
      else {
        $curString = EOS;
      }
      $oldPos = $self->{searchPos};
      if ( $event->{keyDown}{keyCode} == kbBack ) {
        return
          if $self->{searchPos} == -1;
        $self->{searchPos}--;
        if ( $self->{searchPos} == -1 ) {
          $self->{shiftState} = $event->{keyDown}{controlKeyState};
        }
        substr( $curString, $self->{searchPos} + 1 ) = EOS;
      }
      elsif ( $event->{keyDown}{charScan}{charCode} == ord( '.' ) ) {
        my $loc = index( $curString, '.' );
        if ( $loc == -1 ) {
          $self->{searchPos} = -1;
        }
        else {
          $self->{searchPos} = $loc;
        }
      }
      else {
        $self->{searchPos}++;
        if ( $self->{searchPos} == 0 ) {
          $self->{shiftState} = $event->{keyDown}{controlKeyState};
        }
        substr( $curString, $self->{searchPos} ) = 
          chr( $event->{keyDown}{charScan}{charCode} );
      } #/ else [ if ( $event->{keyDown}...)]
      $k = $self->getKey( $curString );
      $self->list()->search( $k, \$value );
      if ( $value < $self->{range} ) {
        $self->getText( \$newString, $value, 255 );
        if ( $equal->( $curString, $newString, $self->{searchPos} + 1 ) ) {
          if ( $value != $oldValue ) {
            $self->focusItem( $value );
            $self->setCursor(
              $self->{cursor}{x} + $self->{searchPos} + 1,
              $self->{cursor}{y}
            );
          }
          else {
            $self->setCursor(
              $self->{cursor}{x} + ( $self->{searchPos} - $oldPos ),
              $self->{cursor}{y}
            );
          }
        } #/ if ( substr( $curString...))
        else {
          $self->{searchPos} = $oldPos;
        }
      } #/ if ( $value < $self->{...})
      else {
        $self->{searchPos} = $oldPos;
      }
      if ( $self->{searchPos} != $oldPos 
        || chr( $event->{keyDown}{charScan}{charCode} ) =~ /^[[:alpha:]]+$/
      ) {
        $self->clearEvent( $event );
      }
    } #/ if ( $charCode != 0 )
  } #/ if ( $event->{what} ==...)
  return;
} #/ sub handleEvent

sub getKey {    # $key ($s)
  my ( $self, $s ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  return $s;
}

sub newList {    # void ($aList)
  my ( $self, $aList ) = @_;
  assert { blessed $self };
  $self->SUPER::newList( $aList );
  $self->{searchPos} = -1;
  return;
}

sub list {    # $sortedCollection ()
  goto &TV::Dialogs::ListBox::list;
}

1
