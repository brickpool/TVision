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

use parent 'UNIVERSAL::Object';

# use own accessors
use subs qw(
  createStatusLine
  createMenuBar
  createDeskTop
);

# declare attributes
use slots::less (
  createStatusLine => sub { die 'required' },
  createMenuBar    => sub { die 'required' },
  createDeskTop    => sub { die 'required' },
);

sub BUILDARGS {    # \%args (%)
  my ( $class, %args ) = @_;
  assert( $class and !ref $class );
  # 'init_arg' is not equal to the field name
  $args{createStatusLine} = delete $args{cStatusLine};
  $args{createMenuBar}    = delete $args{cMenuBar};
  $args{createDeskTop}    = delete $args{cDeskTop};
  # 'required' arguments
  assert ( ref $args{createStatusLine} eq 'CODE' );
  assert ( ref $args{createMenuBar} eq 'CODE' );
  assert ( ref $args{createDeskTop} eq 'CODE' );
  return \%args;
} #/ sub BUILDARGS

sub createStatusLine {    # $statusLine ($r)
  my ( $self, $r ) = @_;
  assert ( blessed $self );
  assert ( ref $r );
  return $self->{createStatusLine}->( bounds => $r );
}

sub createMenuBar {    # $menuBar ($r)
  my ( $self, $r ) = @_;
  assert ( blessed $self );
  assert ( ref $r );
  return $self->{createMenuBar}->( bounds => $r );
}

sub createDeskTop {    # $deskTop ($r)
  my ( $self, $r ) = @_;
  assert ( blessed $self );
  assert ( ref $r );
  return $self->{createDeskTop}->( bounds => $r );
}

1
