=pod

=head1 DESCRIPTION

TView exposed member functions.

=head1 COPYRIGHT AND LICENCE

Turbo Vision - Version 2.0
 
  Copyright (c) 1994 by Borland International
  All Rights Reserved.

The following content was taken from the framework
"A modern port of Turbo Vision 2.0", which is licensed under MIT licence.

Copyright 2019-2021 by magiblot <magiblot@hotmail.com>

=head1 SEE ALSO

I<tvexposd.asm>, I<tvexposd.cpp>

=cut

package TV::Views::View::Exposed;

use strict;
use warnings;

use TV::Views::Const qw( :sfXXXX );

my $eax = 0;
my $ebx = 0;
my $ecx = 0;
my $esi = 0;
my $target = undef;
        
use subs qw(
  L0
  L1
  L10
  L11
  L12
  L13
  L20
  L21
  L22
  L23
);

sub L0 {    # $bool ($dest)
  my ( $dest ) = @_;
  return !!0
    unless $dest->{state} & SF_EXPOSED;
  return !!0
    if $dest->{size}{x} <= 0
    || $dest->{size}{y} <= 0;
  return L1( $dest );
}

sub L1 {    # $bool ($dest)
  my ( $dest ) = @_;
  my $i = 0;
  do {
    $eax = $i;
    $ebx = 0;
    $ecx = $dest->{size}{x};
    return !!1
      unless L11( $dest );
    $i++;
  } while ( $i < $dest->{size}{y} );
  return !!0;
} #/ sub L1

sub L10 {    # $bool ($dest)
  my ( $dest ) = @_;
  my $owner = $dest->owner();
  return !!0
    if $owner->{buffer} != 0
    || $owner->{lockFlag} != 0;
  return L11( $owner );
}

sub L11 {    # $bool ($dest)
  my ( $dest ) = @_;
  $target = $dest;
  $eax += $dest->{origin}{y};
  $ebx += $dest->{origin}{x};
  $ecx += $dest->{origin}{x};
  my $owner = $dest->owner();
  return !!0
    unless $owner;
  return !!1
    if $eax < $owner->{clip}{a}{y};
  return !!1
    if $eax >= $owner->{clip}{b}{y};
  return L12( $owner )
    if $ebx >= $owner->{clip}{a}{x};
  $ebx = $owner->{clip}{a}{x};
  return L12( $owner );
} #/ sub L11

sub L12 {    # $bool ($owner)
  my ( $owner ) = @_;
  return L13( $owner )
    if $ecx <= $owner->{clip}{b}{x};
  $ecx = $owner->{clip}{b}{x};
  return L13( $owner );
}

sub L13 {    # $bool ($owner)
  my ( $owner ) = @_;
  return !!1
    if $ebx >= $ecx;
  return L20( $owner->last() );
}

sub L20 {    # $bool ($dest)
  my ( $dest ) = @_;
  my $next = $dest->next();
  return L10( $next )
    if $next == $target;
  return L21( $next );
}

sub L21 {    # $bool ($next)
  my ( $next ) = @_;
  return L20( $next )
    unless $next->{state} & SF_VISIBLE;
  $esi = $next->{origin}{y};
  return L20( $next )
    if $eax < $esi;
  $esi += $next->{size}{y};
  return L20( $next )
    if $eax >= $esi;
  $esi = $next->{origin}{x};
  return L22( $next )
    if $ebx < $esi;
  $esi += $next->{size}{x};
  return L20( $next )
    if $ebx >= $esi;
  $ebx = $esi;
  return L20( $next )
    if $ebx < $ecx;
  return !!1;
} #/ sub L21

sub L22 {    # $bool ($next)
  my ( $next ) = @_;
  return L20( $next )
    if $ecx <= $esi;
  $esi += $next->{size}{x};
  return L23( $next )
    if $ecx > $esi;
  $ecx = $next->{origin}{x};
  return L20( $next );
} #/ sub L22

sub L23 {    # $bool ($next)
  my ( $next ) = @_;
  my $_target   = $target;
  my $_esi      = $esi;
  my $_ecx      = $ecx;
  my $_eax      = $eax;
  $ecx = $next->{origin}{x};
  my $b = L20( $next );
  $eax    = $_eax;
  $ecx    = $_ecx;
  $ebx    = $_esi;
  $target = $_target;
  return L20( $next )
    if $b;
  return !!0;
} #/ sub L23

1
