package TV::App::ProgInit;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TProgInit
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw( blessed );

sub TProgInit() { __PACKAGE__ }

# predeclare attributes
use fields qw(
  createStatusLine
  createMenuBar
  createDeskTop
);

# use own accessors
use subs qw(
  createStatusLine
  createMenuBar
  createDeskTop
);

{
  require TV::Objects::Object;
  *mk_accessors = \&TV::Objects::Object::mk_accessors;
  *mk_constructor = \&TV::Objects::Object::mk_constructor;
}

__PACKAGE__
  ->mk_constructor
  ->mk_accessors;

sub BUILDARGS {    # \%args (%args)
  my ( $class, %args ) = @_;
  assert( $class and !ref $class );
  $args{createStatusLine} = delete $args{cStatusLine};
  $args{createMenuBar}    = delete $args{cMenuBar};
  $args{createDeskTop}    = delete $args{cDeskTop};
  return {%args};
} #/ sub BUILDARGS

sub BUILD {    # void (| \%args)
  my ( $self, $args ) = @_;
  assert ( blessed $self );
  assert ( ref $self->{createStatusLine} eq 'CODE' );
  assert ( ref $self->{createMenuBar} eq 'CODE' );
  assert ( ref $self->{createDeskTop} eq 'CODE' );
  return;
}

sub createStatusLine {    # $statusLine ($r)
  my ( $self, $r ) = @_;
  assert ( blessed $self );
  assert ( blessed $r );
  return $self->{createStatusLine}->( bounds => $r );
}

sub createMenuBar {    # $menuBar ($r)
  my ( $self, $r ) = @_;
  assert ( blessed $self );
  assert ( blessed $r );
  return $self->{createMenuBar}->( bounds => $r );
}

sub createDeskTop {    # $deskTop ($r)
  my ( $self, $r ) = @_;
  assert ( blessed $self );
  assert ( blessed $r );
  return $self->{createDeskTop}->( bounds => $r );
}

1
