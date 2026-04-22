package TV::StdDlg::FileInputLine;
# ABSTRACT: # ABSTRACT: Input line view for file dialog focus handling

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TFileInputLine
  new_TFileInputLine
);

use TV::toolkit;
use TV::toolkit::Types qw(
  is_Object
  :types
);

use TV::Dialogs::InputLine;
use TV::Drivers::Const qw( evBroadcast );
use TV::StdDlg::Const qw(
  cmFileFocused
  FA_DIREC
);
use TV::StdDlg::Util qw( fexpand );
use TV::Views::Const qw( sfSelected );

sub TFileInputLine() { __PACKAGE__ }
sub name() { 'TFileInputLine' };
sub new_TFileInputLine { __PACKAGE__->from(@_) }

extends TInputLine;

sub BUILDARGS {    # \%args (|%args)
  state $sig = signature(
    method => 1,
    named => [
      bounds    => Object,
      maxLen    => Int, { alias => 'aMaxLen' },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{eventMask} = evBroadcast;
  return;
}

sub from {    # $obj ($aLimit, $aDelta)
  state $sig = signature(
    method => 1,
    pos    => [Object, Int],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], maxLen => $args[1] );
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  $self->SUPER::handleEvent( $event );

  if ( $event->{what} == evBroadcast
    && $event->{message}{command} == cmFileFocused
    && !( $self->{state} & sfSelected )
  ) {
    # Prevents incorrect display in the input line if wildCard has
    # already been expanded.
    assert ( is_Object $event->{message}{infoPtr} );
    assert ( defined $event->{message}{infoPtr}->name );
    if ( $event->{message}{infoPtr}->attr & FA_DIREC ) {
      $self->{data} = $self->{owner}->wildCard;
      if ( $self->{data} !~ /[:\\]/ ) {
        $self->{data} = $event->{message}{infoPtr}->name
                      . "\\" 
                      . $self->{owner}->wildCard;
      }
      else {
        # Insert "<name>\\" between last name/wildcard and last '\'
        fexpand( $self->{data} );    # Insure complete expansion to begin with
        my $pos = rindex( $self->{data}, '\\' );
        my $nm  = $event->{message}{infoPtr}->name;
        if ( $pos >= 0 ) {
          my $offset = $pos + 1;       # position after last '\'
          substr( $self->{data}, $offset, 0 ) = $nm . '\\';
        }
        else {
          # No backslash found: prepend "<name>\"
          $self->{data} = $nm . '\\' . $self->{data};
        }
        fexpand( $self->{data} );    # Expand again incase it was '..'.
      }
    }
    else {
      $self->{data} = $event->{message}{infoPtr}->name;
      $self->drawView();
    }
  }
  return;
} #/ sub handleEvent

1
