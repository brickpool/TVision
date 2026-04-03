package TV::StdDlg::SortedListBox;
# ABSTRACT: TListBox subclass providing automatic item sorting

use 5.010;
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

use PerlX::Assert::PP;
use TV::toolkit;
use TV::toolkit::Params qw( signature );
use TV::toolkit::Types qw(
  :is
  :types
);

use TV::Const qw( EOS );
use TV::Dialogs::ListBox;
use TV::Drivers::Const qw(
  :evXXXX
  kbBack
);
use TV::Objects::SortedCollection;
use TV::Views::Const qw( cmReleasedFocus );

sub TSortedListBox() { __PACKAGE__ }
sub name() { 'TSortedListBox' }
sub new_TSortedListBox { __PACKAGE__->from( @_ ) }

extends TListBox;

# declare attributes
has shiftState => ( is => 'ro',   default =>  0 );
has searchPos  => ( is => 'bare', default => -1 );

my $equal = sub {    # $bool ($s1, $s2, $count)
  my ( $s1, $s2, $count ) = @_;
  assert ( is_Str $s1 );
  assert ( is_Str $s2 );
  assert ( is_PositiveOrZeroInt $count );
  return lc( substr( $s1, 0, $count ) ) eq lc( substr( $s2, 0, $count ) );
};

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->showCursor();
  $self->setCursor( 1, 0 );
  return;
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );

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
  state $sig = signature(
    method => Object,
    pos    => [Str],
  );
  my ( $self, $s ) = $sig->( @_ );
  return $s;
}

sub newList {    # void ($aList)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $aList ) = $sig->( @_ );
  $self->SUPER::newList( $aList );
  $self->{searchPos} = -1;
  return;
}

sub list {    # $sortedCollection ()
  goto &TV::Dialogs::ListBox::list;
}

1
