package TV::Dialogs::HistoryViewer::HistList;
# ABSTARCT: Implements the behavior of the HistRec list

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use PerlX::Assert::PP;
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

# predeclare private subs
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

sub historyAdd {    # void ($id, $str|undef)
  my ( $id, $str ) = @_;
  assert { @_ == 2 };
  assert { looks_like_number $id };
  assert { !defined $str or !ref $str };

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
  assert { @_ == 1 };
  assert { looks_like_number $id };

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
  assert { @_ == 2 };
  assert { looks_like_number $id };
  assert { looks_like_number $index };

  $startId->( $id );
  $advanceStringPointer->() for ( 0..$index );
  return $curRec >= 0
    ? $historyBlock->[$curRec]->{str}
    : '';
}

sub clearHistory {    # void ()
  assert { @_ == 0 };
  $historyBlock = [];
  $historyUsed = @$historyBlock;
  return
}

sub initHistory {   # void ()
  assert { @_ == 0 };
  clearHistory();
  return
}

sub doneHistory {   # void ()
  assert { @_ == 0 };
  $historyBlock = undef;
  $historyUsed = 0;
  return
}

1

__END__

=pod

=head1 NAME

TV::Dialogs::HistoryViewer::HistList - manages Turbo Vision-style input history lists

=head1 SYNOPSIS

  use TV::Dialogs::HistoryViewer::HistList qw(historyAdd historyStr historyCount);

  historyAdd(1, "hello");
  my $count = historyCount(1);
  my $entry = historyStr(1, 0);

=head1 DESCRIPTION

C<HistList> provides a simple history buffer used by Turbo Vision input controls.  
Entries are grouped by numeric IDs and stored in an internal list structure.  
The implementation mimics the behavior of the original Turbo Vision history 
code.  

It supports adding entries, retrieving them, counting them, and clearing the 
buffer. The structure of the history buffer is as follows:

  $historyBlock = [
    { id => Int, str => Str },
    { id => Int, str => Str },
    ...
  ];

=head1 FUNCTIONS

=head2 historyAdd

Adds a string to the history group identified by the given ID.

=head2 historyCount

Returns the number of entries associated with the given history ID.

=head2 historyStr

Returns the Nth history string for the specified ID.

=head2 clearHistory

Clears all history entries.

=head2 initHistory

Initializes the history structure and clears all entries.

=head2 doneHistory

Destroys all history data and resets the module state.

=head1 AUTHORS

=over

=item Turbo Vision Development Team

=item J. Schneider <brickpool@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2025-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution).

=cut
