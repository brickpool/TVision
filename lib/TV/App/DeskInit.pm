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
  *mk_accessors = \&TV::Objects::Object::mk_accessors;
  *mk_constructor = \&TV::Objects::Object::mk_constructor;
}

__PACKAGE__
  ->mk_constructor
  ->mk_accessors;

sub BUILDARGS {    # \%args (%)
  my ( $class, %args ) = @_;
  assert ( $class and !ref $class );
  # 'init_arg' is not equal to the field name
  $args{createBackground} = delete $args{cBackground};
  # 'required' arguments
  assert ( ref $args{createBackground} eq 'CODE' );
  return \%args;
}

sub createBackground {    # $background ($r)
  my ( $self, $r ) = @_;
  assert ( blessed $self );
  assert ( ref $r );
  return $self->{createBackground}->( bounds => $r );
}

1
