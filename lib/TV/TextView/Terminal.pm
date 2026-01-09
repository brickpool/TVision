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
use List::Util qw( min );
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
);
use TV::TextView::TextDevice;
use TV::toolkit;

sub TTerminal() { __PACKAGE__ }
sub name() { 'TTerminal' }
sub new_TTerminal { __PACKAGE__->from(@_) }

extends TTextDevice;

# declare attributes
has bufSize      => ( is => 'ro', default => sub { die 'required' } );
has buffer       => ( is => 'ro', default => sub { '' } );
has queFront     => ( is => 'ro', default => sub { 0 } );
has queBack      => ( is => 'ro', default => sub { 0 } );

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  local $Params::Check::PRESERVE_CASE = 1;
  my $args1 = $class->SUPER::BUILDARGS( @_ );
  my $args2 = STRICT ? check( {
    # 'required' arguments
    aBufSize => { required => 1, defined => 1, allow => qr/^\d+$/ },
  } => { @_ } ) || Carp::confess( last_error ) : { @_ };
  # 'init_arg' is not the same as the field name.
  $args2->{bufSize} = delete $args2->{aBufSize};
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
  return $class->new( bounds => $_[0], aHScrollBar => $_[1], 
    aVScrollBar => $_[2], aBufSize => $_[3] );
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

sub bufInc {    # void ($val)
  my ( $self, undef ) = @_;
  alias: for my $val ( $_[1] ) {
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( looks_like_number $val );
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

sub nextLine {    # $offset ($pos)
  my ( $self, $pos ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( looks_like_number $pos );

  if ( $pos != $self->{queFront} ) {

    # Loop until newline or queFront is reached
    while ( substr( $self->{buffer}, $pos, 1 ) ne "\n"
      && $pos != $self->{queFront}
    ) {
      $self->bufInc( $pos );    # Increment position
    }

    # If not at queFront, move one more position
    if ( $pos != $self->{queFront} ) {
      $self->bufInc( $pos );
    }
  } #/ if ( $pos != $self->{queFront...})

  return $pos;
} #/ sub nextLine

# The following subroutine was taken from the framework
# "A modern port of Turbo Vision 2.0", which is licensed under MIT licence.
#
# Copyright 2019-2021 by magiblot <magiblot@hotmail.com>
#
# I<ttprvlns.cpp>
sub prevLines {    # $offset ($pos, $lines)
  my ( $self, $pos, $lines ) = @_;
  assert ( @_ == 3 );
  assert ( blessed $self );
  assert ( looks_like_number $pos );
  assert ( looks_like_number $lines );

  if ( $lines > 0 && $pos != $self->{queBack} ) {
    do {
      # Stop if we reached the back of the queue
      if ( $pos == $self->{queBack} ) {
        return $self->{queBack};
      }

      # Step back one position in the circular buffer
      $self->bufDec( $pos );

      # Calculate how many characters we can check backwards
      my $count = ( $pos >= $self->{queBack} )
                ? ( $pos - $self->{queBack} + 1 )
                : ( $pos + 1 );

      # Search backwards for newline within the allowed range
      while ( $count > 0 ) {
        if ( substr( $self->{buffer}, $pos, 1 ) eq "\n" ) {
          $lines--;
          last;    # Found a newline, stop inner loop
        }
        $pos--;
        $count--;
      }
    } while ( $lines > 0 );

    # Move forward one position after finishing
    $self->bufInc( $pos );
  } #/ if ( $lines > 0 && $pos...)
  return $pos;
} #/ sub prevLines

sub bufDec {    # void ($val)
  my ( $self, undef ) = @_;
  alias: for my $val ( $_[1] ) {
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( looks_like_number $val );
  if ( $val == 0 ) {
    $val = $self->{bufSize} - 1;
  }
  else {
    $val--;
  }
  return;
  } #/ alias
} #/ sub bufDec

sub queEmpty {    # $bool ()
  my ( $self ) = @_;
  assert( @_ == 1 );
  assert( blessed $self );
  return $self->{queBack} == $self->{queFront};
}

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

 $self->bufDec($val);

Decrements a buffer position in the circular buffer.

=head2 bufInc

 $self->bufInc($val);

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
