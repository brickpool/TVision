=pod

=head1 DESCRIPTION

TView resetCursor member functions.

=head1 COPYRIGHT AND LICENSE

Turbo Vision - Version 2.0
 
  Copyright (c) 1994 by Borland International
  All Rights Reserved.

The following content was taken from the framework
"A modern port of Turbo Vision 2.0", which is licensed under MIT license.

Copyright 2019-2021 by magiblot <magiblot@hotmail.com>

=head1 SEE ALSO

I<tvcursor.asm>, I<tvcursor.cpp>

=cut

package TV::Views::View::Cursor;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use TV::Drivers::HardwareInfo;
use TV::Drivers::Screen;
use TV::Views::Const qw( :sfXXXX );

my $self = undef;
my $x = 0;
my $y = 0;

use subs qw(
  resetCursor
  computeCaretSize
  caretCovered
  decideCaretSize
);

# import global variables
use vars qw(
  $cursorLines
);
{
  no strict 'refs';
  *cursorLines = \${ TScreen . '::cursorLines' };
}

sub resetCursor {    # void ($p)
  my ( $p ) = @_;
  $self = $p;
  $x    = $self->{cursor}->{x};
  $y    = $self->{cursor}->{y};
  my $caretSize = computeCaretSize();
  if ( $caretSize ) {
    THardwareInfo->setCaretPosition( $x, $y );
  }
  THardwareInfo->setCaretSize( $caretSize );
  return;
} #/ sub resetCursor

sub computeCaretSize {    # $int ()
  if ( !( ~$self->{state} & ( sfVisible | sfCursorVis | sfFocused ) ) ) {
    my $v = $self;
    while ( $y >= 0 && $y < $v->{size}->{y} 
         && $x >= 0 && $x < $v->{size}->{x} 
    ) {
      $y += $v->{origin}->{y};
      $x += $v->{origin}->{x};
      if ( $v->owner() ) {
        if ( $v->owner()->{state} & sfVisible ) {
          if ( caretCovered( $v ) ) {
            last;
          }
          $v = $v->owner();
        }
        else {
          last;
        }
      } #/ if ( $v->owner() )
      else {
        return decideCaretSize();
      }
    } #/ while ( $y >= 0 && $y < $v...)
  } #/ if ( !( ~$self->{state...}))
  return 0;
} #/ sub computeCaretSize

sub caretCovered {    # $bool ($v)
  my ( $v ) = @_;
  my $u = $v->owner()->last()->next();
  for ( ; $u != $v ; $u = $u->next() ) {
    if ( ( $u->{state} & sfVisible )
      && ( $u->{origin}->{y} <= $y && $y < $u->{origin}->{y} + $u->{size}->{y} )
      && ( $u->{origin}->{x} <= $x && $x < $u->{origin}->{x} + $u->{size}->{x} ) 
    ) {
      return !!1;
    }
  }
  return !!0;
} #/ sub caretCovered

sub decideCaretSize {    # $int()
  if ( $self->{state} & sfCursorIns ) {
    return 100;
  }
  return $cursorLines & 0x0f;
}

1
