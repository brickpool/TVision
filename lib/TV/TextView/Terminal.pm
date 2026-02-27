package TV::TextView::Terminal;
# ABSTRACT: TTerminal is a simple text view class

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TTerminal
  new_TTerminal
);

require bytes;
use Carp ();
use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use List::Util qw( min max );
use Params::Check qw(
  check
  last_error
);
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::Views::Const qw(
  gfGrowHiX
  gfGrowHiY
  maxViewWidth
);
use TV::Views::DrawBuffer;
use TV::TextView::TextDevice;
use TV::toolkit;

sub TTerminal() { __PACKAGE__ }
sub name() { 'TTerminal' }
sub new_TTerminal { __PACKAGE__->from(@_) }

extends TTextDevice;

# declare attributes
has bufSize      => ( is => 'ro' );
has buffer       => ( is => 'ro' );
has queFront     => ( is => 'ro' );
has queBack      => ( is => 'ro' );

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  local $Params::Check::PRESERVE_CASE = 1;
  my $args1 = $class->SUPER::BUILDARGS( @_ );
  my $args2 = check( {
    # set 'default' values, init_args => undef
    buffer   => { default => '', no_override => 1 },
    queFront => { default => 0, no_override => 1 },
    queBack  => { default => 0, no_override => 1 }, 
    # 'required' arguments
    bufSize  => { required => 1, defined => 1, allow => qr/^\d+$/ },
  } => { @_ } ) || Carp::confess( last_error );
  return { %$args1, %$args2 };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  $self->{growMode} = gfGrowHiX | gfGrowHiY;
  $self->{bufSize}  = min( 32000, $args->{bufSize} );
  $self->{buffer}   = "\0" x $self->{bufSize};
  $self->setLimit( 0, 1 );
  $self->setCursor( 0, 0 );
  $self->showCursor();
  return;
} #/ sub new

sub from {    # $term ($bounds, $aHScrollBar, $aVScrollBar, aBufSize)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 4 );
  return $class->new( bounds => $_[0], hScrollBar => $_[1], 
    vScrollBar => $_[2], bufSize => $_[3] );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  $self->{buffer} = undef;
  return;
}

# The following subroutine was taken from the framework
# "A modern port of Turbo Vision 2.0", which is licensed under MIT licence.
#
# Copyright 2019-2021 by magiblot <magiblot@hotmail.com>
#
# I<textview.cpp>
sub do_sputn {    # $num ($s, $count)
  my ( $self, $s, $count ) = @_;
  assert ( @_ == 3 );
  assert ( blessed $self );
  assert ( defined $s and !ref $s );
  assert ( looks_like_number $count );
  
  my $screenLines = $self->{limit}{y};
  my $i;

  if ( $count > $self->{bufSize} - 1 ) {
    $s     = bytes::substr( $s, $count - ( $self->{bufSize} - 1 ) );
    $count = $self->{bufSize} - 1;
  }

  $screenLines += ( $s =~ tr/\n// );

  while ( !$self->canInsert( $count ) ) {
    $self->{queBack} = $self->nextLine( $self->{queBack} );
    if ( $screenLines > 1 ) {
      $screenLines--;
    }
  }

  if ( $self->{queFront} + $count >= $self->{bufSize} ) {
    $i = $self->{bufSize} - $self->{queFront};
    bytes::substr(
      $self->{buffer}, $self->{queFront}, $i, 
      bytes::substr( $s, 0, $i )
    );
    bytes::substr(
      $self->{buffer}, 0, $count - $i, 
      bytes::substr( $s, $i, $count - $i )
    );
    $self->{queFront} = $count - $i;
  }
  else {
    bytes::substr(
      $self->{buffer}, $self->{queFront}, $count, 
      bytes::substr( $s, 0, $count )
    );
    $self->{queFront} += $count;
  }

  # drawLock: avoid redundant calls to drawView()
  $self->{drawLock}++;
  $self->setLimit( $self->{limit}{x}, $screenLines );
  $self->scrollTo( 0, $screenLines + 1 );
  $self->{drawLock}--;

  $self->drawView();
  return $count;
}

sub bufInc {    # void (\$val)
  my ( $self, $val_ref ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( ref $val_ref and looks_like_number $$val_ref );
  alias: for my $val ( $$val_ref ) {
  if ( ++$val >= $self->{bufSize} ) {
    $val = 0;
  }
  return;
  } #/ alias
} #/ sub bufInc

sub canInsert {    # $bool ($amount)
  my ( $self, $amount ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( looks_like_number $amount );

  my $T = ( $self->{queFront} < $self->{queBack} )
        ? ( $self->{queFront} + $amount )
        : ( $self->{queFront} - $self->{bufSize} + $amount );
  return $self->{queBack} > $T;
}

sub calcWidth {    # $width ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  ...
}

# The following subroutine was taken from the framework
# "A modern port of Turbo Vision 2.0", which is licensed under MIT licence.
#
# Copyright 2019-2021 by magiblot <magiblot@hotmail.com>
#
# I<textview.cpp>
sub draw {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );

  my $b = TDrawBuffer->new();
  my $s;
  my $sLen;
  my ( $x, $y );
  my ( $begLine, $endLine, $linePos );
  my $bottomLine;
  my $color = $self->mapColor( 1 );

  $self->setCursor( -1, -1 );

  $bottomLine = $self->{size}{y} + $self->{delta}{y};
  if ( $self->{limit}{y} > $bottomLine ) {
    $endLine =
      $self->prevLines( $self->{queFront}, $self->{limit}{y} - $bottomLine );
    $self->bufDec( \$endLine );
  }
  else {
    $endLine = $self->{queFront};
  }

  if ( $self->{limit}{y} > $self->{size}{y} ) {
    $y = $self->{size}{y} - 1;
  }
  else {
    for ( $y = $self->{limit}{y} ; $y < $self->{size}{y} ; $y++ ) {
      $self->writeChar( 0, $y, ' ', 1, $self->{size}{x} );
    }
    $y = $self->{limit}{y} - 1;
  }

  for ( ; $y >= 0 ; $y-- ) {
    $x       = 0;
    $begLine = $self->prevLines( $endLine, 1 );
    $linePos = $begLine;

    while ( $linePos != $endLine ) {
      # Processing lines of any length by copying only the characters to be 
      # displayed in $s, assuming that these are < maxViewWidth.
      if ( $endLine >= $linePos ) {
        my $cpyLen = min( $endLine - $linePos, maxViewWidth );
        $s    = substr( $self->{buffer}, $linePos, $cpyLen );
        $sLen = $cpyLen;
      }
      else {
        my $fstCpyLen = min( $self->{bufSize} - $linePos, maxViewWidth );
        my $sndCpyLen = min( $endLine, maxViewWidth - $fstCpyLen );
        $s = substr( $self->{buffer}, $linePos, $fstCpyLen )
           . substr( $self->{buffer}, 0, $sndCpyLen );
        $sLen = $fstCpyLen + $sndCpyLen;
      }

      # Report any overlapping characters at the end
      assert ( $sLen == length $s );
      if ( $linePos >= $self->{bufSize} - $sLen ) {
        $linePos = $sLen - ( $self->{bufSize} - $linePos );
      }
      else {
        $linePos += $sLen;
      }

      $x += do { 
        $b->moveStr( $x, $s, $color );
        length $s;
      };
    } #/ while ( $linePos != $endLine)

    $b->moveChar( $x, ' ', $color, max( $self->{size}{x} - $x, 0 ) );
    $self->writeBuf( 0, $y, $self->{size}{x}, 1, $b );

    # Draw the cursor when this is the last line
    if ( $endLine == $self->{queFront} ) {
      $self->setCursor( $x, $y );
    }
    $endLine = $begLine;
    $self->bufDec( \$endLine );
  } #/ for ( ; $y >= 0 ; $y-- )
  return;
}

sub nextLine {    # $offset ($pos)
  my ( $self, $pos ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( looks_like_number $pos );

  if ( $pos != $self->{queFront} ) {
    while ( substr( $self->{buffer}, $pos, 1 ) ne "\n"
      && $pos != $self->{queFront}
    ) {
      $self->bufInc( \$pos );
    }
    if ( $pos != $self->{queFront} ) {
      $self->bufInc( \$pos );
    }
  }
  return $pos;
} #/ sub nextLine

# The following two subroutines was taken from the framework
# "A modern port of Turbo Vision 2.0", which is licensed under MIT licence.
#
# Copyright 2019-2021 by magiblot <magiblot@hotmail.com>
#
# I<ttprvlns.cpp>
my $findLfBackwards = sub {    # $bool ($buffer, $pos, $count)
  my ( $buffer, undef, $count ) = @_;
  alias: for my $pos ( $_[1] ) {
  # Pre: count >= 1.
  # Post: 'pos' points to the last checked character.
  ++$pos;
  do {
    return !!1 
      if substr( $buffer, --$pos, 1 ) eq "\n";
  } while ( --$count > 0 );
  return !!0;
  } #/ alias: for my $pos ( $_[1] )
};

sub prevLines {    # $offset ($pos, $lines)
  my ( $self, $pos, $lines ) = @_;
  assert ( @_ == 3 );
  assert ( blessed $self );
  assert ( looks_like_number $pos );
  assert ( looks_like_number $lines );

  if ( $lines > 0 && $pos != $self->{queBack} ) {
    do {
      return $self->{queBack} 
          if $pos == $self->{queBack};
      $self->bufDec( \$pos );
      my $count = ( $pos >= $self->{queBack}
                  ? $pos - $self->{queBack}
                  : $pos ) + 1;
      --$lines if $findLfBackwards->( $self->{buffer}, $pos, $count );
    } while ( $lines > 0 );
    $self->bufInc( \$pos );
  } #/ if ( $lines > 0 && $pos...)
  return $pos;
} #/ sub prevLines

sub queEmpty {    # $bool ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  return $self->{queBack} == $self->{queFront};
}

sub bufDec {    # void ($val)
  my ( $self, $val_ref ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( ref $val_ref and looks_like_number $$val_ref );
  alias: for my $val ( $$val_ref ) {
  if ( $val == 0 ) {
    $val = $self->{bufSize} - 1;
  }
  else {
    $val--;
  }
  return;
  } #/ alias
} #/ sub bufDec

1

__END__

=head1 NAME

TV::TextView::Terminal - A simple text view class

=head1 DESCRIPTION

C<TTerminal> is a simple, scrollable, write-only text view provided by Turbo 
Vision. It acts as a terminal-like output device with an internal circular 
buffer for storing text. The class extends C<TTextDevice> and adds buffer 
management and scrolling capabilities.

Typical use cases include:

=over

=item Displaying output in a terminal-like view

=item Implementing log or console windows in text-based applications

=back

=head1 METHODS

=head2 new

  my $term = TTerminal->new(%args);

Creates a new C<TTerminal> instance with the given arguments.

=over

=item bounds

The bounds of the scroller (I<TRect>).

=item aHScrollBar

The horizontal scroll bar of the scroller (I<TScrollBar>).

=item aVScrollBar

The vertical scroll bar of the scroller (I<TScrollBar>).

=item aBufSize

Defines the buffer size (I<Int>).

=back

=head2 new_TTerminal

 my $term = new_TTerminal($bounds, $aHScrollBar, $aVScrollBar, $aBufSize);

Factory constructor for creating a new terminal object.

=head2 bufDec

 $self->bufDec(\$val);

Decrements a buffer position in the circular buffer.

=head2 bufInc

 $self->bufInc(\$val);

Increments a buffer position in the circular buffer.

=head2 canInsert

 my $bool = $self->canInsert($amount);

Checks if the buffer can insert the specified amount of data.

=head2 do_sputn

 my $num = $self->do_sputn($s, $count);

Writes a string of a given length into the circular buffer and updates the view.

=head2 name

 my $name = $self->name();

Returns the name of the class (C<"TTerminal">).

=head2 nextLine

 my $offset = $self->nextLine($pos);

Returns the position of the next line in the buffer.

=head2 prevLines

 my $offset = $self->prevLines($pos, $lines);

Moves backwards by a given number of lines in the buffer.

=head2 queEmpty

 my $bool = $self->queEmpty();

Checks if the buffer queue is empty.

=head1 SEE ALSO

I<ttprvlns.asm>, I<ttprvlns.cpp>

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

Copyright (c) 2019-2026 the L</AUTHORS> and L</CONTRIBUTORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution).

=cut
