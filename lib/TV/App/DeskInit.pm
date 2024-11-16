package TV::App::DeskInit;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TDeskInit
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw( blessed );

use TV::Util;

sub TDeskInit() { __PACKAGE__ }

# predeclare attributes
use fields qw(
  createBackground
);

# use own accessors
use subs qw(
  createBackground
);

{
  require TV::Objects::Object;
  *mk_accessors = \&TV::Objects::Object::mk_rw_accessors;
  *mk_constructor = \&TV::Objects::Object::mk_constructor;
}

__PACKAGE__
  ->mk_constructor
  ->mk_accessors;

sub BUILDARGS {    # \%args (\&cBackground)
  my ( $class, $cBackground ) = @_;
  assert ( $class and !ref $class );
  return { createBackground => $cBackground };
}

sub BUILD {    # void (| $args)
  my ( $self, $args ) = @_;
  assert ( blessed $self );
  assert ( ref $self->{createBackground} eq 'CODE' );
  return;
}

sub createBackground { # $background ($r)
  my ( $self, $r ) = @_;
  assert ( blessed $self );
  assert ( blessed $r );
  return $self->{createBackground}->($r);
}

1
