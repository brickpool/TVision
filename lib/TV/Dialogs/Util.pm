package TV::Dialogs::Util;
# ABSTRACT: various utility functions for Turbo Vision dialogs

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(
  hotKey
  prevWord
  nextWord
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw(
  looks_like_number
);

sub hotKey ($) {    # $hotkey ($s)
  my ( $s ) = @_;
  assert ( @_ == 1 );
  assert ( defined $s and !ref $s );

  my $pos = index( $s, '~' );
  if ( $pos != -1 && $pos + 1 < length( $s ) ) {
    return uc substr( $s, $pos + 1, 1 );
  }
  else {
    return '';
  }
} #/ sub hotKey

sub prevWord ($) {    # $index ($s, $pos)
  my ( $s, $pos ) = @_;
  assert ( @_ == 2 );
  assert ( defined $s and !ref $s );
  assert ( looks_like_number $pos );

  for ( my $i = $pos - 1 ; $i >= 1 ; --$i ) {
    my $curr = substr( $s, $i,     1 );
    my $prev = substr( $s, $i - 1, 1 );
    if ( $curr ne ' ' && $prev eq ' ' ) {
      return $i;
    }
  }
  return 0;
} #/ sub prevWord

sub nextWord ($) {    # $index ($s, $pos)
  my ( $s, $pos ) = @_;
  assert ( @_ == 2 );
  assert ( defined $s and !ref $s );
  assert ( looks_like_number $pos );

  my $len = length( $s );
  for ( my $i = $pos ; $i < $len - 1 ; ++$i ) {
    my $curr = substr( $s, $i,     1 );
    my $next = substr( $s, $i + 1, 1 );
    if ( $curr eq ' ' && $next ne ' ' ) {
      return $i + 1;
    }
  }
  return $len;
} #/ sub nextWord

1

__END__

=head1 NAME

TV::Dialogs::Util - Utility functions for Turbo Vision dialogs

=head1 DESCRIPTION

This module provides helper functions commonly used in text-based user 
interface components: extracting marked hotkeys from strings, locating the 
previous word boundary, and locating the next word boundary within a string. 
These functions are intended to support navigation and keyboard-interaction 
logic.

=head1 FUNCTIONS

=head2 hotKey

 my $hotkey = hotKey($s);

Extracts a hotkey indicator from the given string.

A hotkey is defined as the character immediately following a tilde
(C<~>). If such a marker exists, the character is returned in uppercase.
If no hotkey marker is found, the function returns C<''>.

Example:

    my $key = hotKey("~S~ave");
    # $key is 'S'

=head2 nextWord

 my $index = nextWord($s, $pos);


Returns the index of the beginning of the next word in the string.

A word is any sequence of non‑space characters. The function searches
forward from C<$pos> and returns the index where a space transitions
into a non‑space character. If no next word exists, the function returns
C<length($s)>.

=head2 prevWord

 my $index = prevWord($s, $pos);

Returns the index of the beginning of the previous word in the string.

A word is considered any sequence of non‑space characters.
The function searches backwards from C<$pos - 1> and returns the
index where a space transitions into a non‑space character. If no
previous word exists, the function returns C<0>.

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
