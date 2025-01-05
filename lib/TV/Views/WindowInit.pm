package TV::Views::WindowInit;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TWindowInit
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw( blessed );

use TV::toolkit;

sub TWindowInit() { __PACKAGE__ }

# declare attributes
slots createFrame => ( is => 'bare', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%)
  my ( $class, %args ) = @_;
  assert ( $class and !ref $class );
  # 'init_arg' is not equal to the field name
  $args{createFrame} = delete $args{cFrame};
  return \%args;
}

sub createFrame {    # $frame ($r)
  my ( $self, $r ) = @_;
  assert ( blessed $self );
  assert ( ref $r );
  return $self->{createFrame}->( bounds => $r );
}

1
