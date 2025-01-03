=pod

=head1 NAME

TV::Dialogs::History::HistList - implements the behavior of the HistRec list

=head1 DESCRIPTION

History buffer structure:

  $historyBlock = [
    { id => Int, str => Str },
    { id => Int, str => Str },
    ...
  ];

=cut

package TV::Dialogs::History::HistList;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw( looks_like_number );

use Exporter 'import';
our @EXPORT_OK = qw(
  historyCount
  historyAdd
  historyStr
  clearHistory
  initHistory
  doneHistory
);

# declare global variables
our $historyBlock = undef;   # array reference, not a packed string
our $historySize  = 1024;    # initial size of history block
our $historyUsed  = 0;       # taken from the Turbo Pascal implementation

# predeclare private class subs
my (
  $advanceStringPointer,
  $deleteString,
  $insertString,
  $startId,
);

# declare local variables
my $curId;
my $curRec;

# Advance curRec to next string with an id of $curId
$advanceStringPointer = sub {    # void ()
  $curRec++;
  while ( $curRec < $historyUsed && $historyBlock->[$curRec]->{id} != $curId ) {
    $curRec++;
  }
  $curRec = -1 if $curRec >= $historyUsed;
  return;
};

# Deletes the current string from the table
$deleteString = sub {    # void ()
  splice( @$historyBlock, $curRec, 1 ) 
    if $curRec < @$historyBlock;
  $historyUsed = @$historyBlock;
  return;
};

# Insert a string into the table
$insertString = sub {    # void ($id, $str)
  my ( $id, $str ) = @_;
  my $len = length $str;
  my $n = @$historyBlock;
  my $size = 0;
  for ( reverse @$historyBlock ) {
    last if $len > $historySize - $size;
    $size += length $_->{str};
    $n--;
  }
  splice( @$historyBlock, 0, $n ) if $n > 0;
  push @$historyBlock => { id => $id, str => $str };
  $historyUsed = @$historyBlock;
  return;
};

$startId = sub {    # void ($id)
  $curId = shift;
  $curRec = -1;
  return;
};

sub historyAdd {    # void ($id, $str)
  my ( $id, $str ) = @_;
  assert ( @_ == 2 );
  assert ( looks_like_number $id );
  assert ( !defined $str or !ref $str );

  return unless defined $str;
  $startId->( $id );

  # Delete duplicates
  $advanceStringPointer->();
  while ( $curRec >= 0 ) {
    $deleteString->()
      if $str eq $historyBlock->[$curRec]->{str};
    $advanceStringPointer->();
  }

  $insertString->( $id, $str );
  return;
}

sub historyCount {    # $count ($id)
  my ( $id ) = @_;
  assert ( @_ == 1 );
  assert ( looks_like_number $id );

  $startId->( $id );
  my $count = 0;
  $advanceStringPointer->();
  while ( $curRec >= 0 ) {
    $count++;
    $advanceStringPointer->();
  }
  return $count;
} #/ sub historyCount

sub historyStr {    # $str ($id, $index)
  my ( $id, $index ) = @_;
  assert ( @_ == 2 );
  assert ( looks_like_number $id );
  assert ( looks_like_number $index );

  $startId->( $id );
  $advanceStringPointer->() for ( 0..$index );
  return $curRec >= 0
    ? $historyBlock->[$curRec]->{str}
    : '';
}

sub clearHistory {    # void ()
  assert ( @_ == 0 );
  $historyBlock = [];
  $historyUsed = @$historyBlock;
  return
}

sub initHistory {   # void ()
  assert ( @_ == 0 );
  clearHistory();
  return
}

sub doneHistory {   # void ()
  assert ( @_ == 0 );
  $historyBlock = undef;
  $historyUsed = 0;
  return
}

1
