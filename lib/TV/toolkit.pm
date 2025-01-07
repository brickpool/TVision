package TV::toolkit;

use strict;
use warnings;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:BRICKPOOL';

use Carp ();
use Import::Into;
use Module::Loaded;

our $name;
BEGIN {
  $name = 'Moos';
  foreach my $toolkit ( qw( Moo Moos Moose ) ) {
    if ( Module::Loaded::is_loaded $toolkit ) {
      $name = $toolkit;
      last;
    }
  }

  sub is_Moo   (){ $name eq 'Moo'   }
  sub is_Moos  (){ $name eq 'Moos'  }
  sub is_Moose (){ $name eq 'Moose' }
}
  
sub import {
  my $target = caller;
  if ( $name eq 'Moose' ) {
    require Moose;
    Moose->import::into( $target );
  }
  elsif ( $name eq 'Moo' ) {
    require Moo;
    Moo->import::into( $target );
  }
  else {
    require Moos;
    Moos->import::into( $target );
    _around_hook( $target, 'has', \&_has )
      or Carp::croak( "Cannot inject 'has' method in package '$target'" );
  }
} #/ sub import

sub _around_hook {
  my ( $class, $method, $code ) = @_;
  return
    unless ref \$class eq 'SCALAR'
    && ref \$method eq 'SCALAR'
    && ref $code  eq 'CODE';
  my $fullpkg = "${class}::${method}";
  my $orig    = \&{$fullpkg};
  if ( defined $orig ) {
    no strict 'refs';
    no warnings 'redefine';
    *{"${fullpkg}"} = sub { $code->( $orig, @_ ) };
    return 1;
  }
  return;
} #/ sub _around_hook

sub _has {
  my $next = shift;
  return $next->( @_ ) unless @_ % 2;
  my ( $name, %args ) = @_;
  if ( exists $args{is} && $args{is} eq 'bare' ) {
    $args{is} = 'rw';
    $args{_skip_setup} = 1;
  }
  return $next->( $name, %args );
}

1
