package TV::Views::Frame::Line;
# ABSTRACT: TFrame frameLine member function.

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use List::Util qw( min max );
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::Views::Const qw( cpFrame );
require TV::Views::Frame;

use vars qw( 
  $initFrame
  $frameChars
);
{
  *initFrame = \$TV::Views::Frame::initFrame;
  *frameChars = \$TV::Views::Frame::frameChars;
}

sub TV::Views::Frame::frameLine {
  my ( $self, $frameBuf, $y, $n, $color ) = @_;
  assert ( blessed $self );
  assert ( blessed $frameBuf );
  assert ( looks_like_number $y );
  assert ( looks_like_number $n );
  assert ( looks_like_number $color );

  my $size_x    = $self->{size}{x};
  my $FrameMask = "\0" x $size_x;
  my $x;

  substr( $FrameMask, 0, 1, substr( $initFrame, $n, 1 ) );
  for ( $x = 1 ; $x < $size_x - 1 ; ++$x ) {
    substr( $FrameMask, $x, 1, substr( $initFrame, $n + 1, 1 ) );
  }
  substr( $FrameMask, $size_x - 1, 1, substr( $initFrame, $n + 2, 1 ) );

  my $v = $self->{owner}{last}{next};
  for ( ; $v != $self ; $v = $v->{next} ) {
    if ( ( $v->{options} & $self->{ofFramed} )
      && ( $v->{state} & $self->{sfVisible} ) )
    {
      my $mask = 0;
      if ( $y < $v->{origin}{y} ) {
        if ( $y == $v->{origin}{y} - 1 ) {
          $mask = 0x0A06;
        }
      }
      elsif ( $y < $v->{origin}{y} + $v->{size}{y} ) {
        $mask = 0x0005;
      }
      elsif ( $y == $v->{origin}{y} + $v->{size}{y} ) {
        $mask = 0x0A03;
      }

      if ( $mask ) {
        my $start = max( $v->{origin}{x}, 1 );
        my $end   = min( $v->{origin}{x} + $v->{size}{x}, $size_x - 1 );
        if ( $start < $end ) {
          my $maskLow  = $mask & 0x00FF;
          my $maskHigh = ( $mask & 0xFF00 ) >> 8;
          substr(
            $FrameMask, $start - 1, 1,
            chr( ord( substr( $FrameMask, $start - 1, 1 ) ) | $maskLow )
          );
          substr(
            $FrameMask, $end, 1,
            chr( ord( substr( $FrameMask, $end, 1 ) ) | ( $maskLow ^ $maskHigh ) )
          );
          if ( $maskLow ) {
            for ( $x = $start ; $x < $end ; ++$x ) {
              substr(
                $FrameMask, $x, 1,
                chr( ord( substr( $FrameMask, $x, 1 ) ) | $maskHigh )
              );
            }
          }
        } #/ if ( $start < $end )
      } #/ if ( $mask )
    } #/ if ( ( $v->{options} &...))
  } #/ for ( ; $v != $self ; $v...)

  for ( $x = 0 ; $x < $size_x ; ++$x ) {
    $frameBuf->putChar(
      $x,
      substr( $frameChars, ord( substr( $FrameMask, $x, 1 ) ), 1 )
    );
    $frameBuf->putAttribute( $x, $color );
  }
} #/ sub TV::Views::Frame::frameLine

1

__END__

=pod

=head1 DESCRIPTION

TFrame frameLine member functions.

The content was taken from the framework
"A modern port of Turbo Vision 2.0", which is licensed under MIT license.

=head1 SEE ALSO

I<framelin.asm>, I<framelin.cpp>

=head1 AUTHORS

=over

=item Turbo Vision Development Team

=item J. Schneider <brickpool@cpan.org>

=back

=head1 CONTRIBUTORS

=over

=item magiblot <magiblot@hotmail.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2019-2025 the L</AUTHORS> and L</CONTRIBUTORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution).

=cut
