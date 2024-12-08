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

use parent 'UNIVERSAL::Object';

# use own accessors
use subs qw(
  createBackground
);

# declare attributes
use slots::less (
  createBackground => sub { die 'required' },
);

sub BUILDARGS {    # \%args (%)
  my ( $class, %args ) = @_;
  assert ( $class and !ref $class );
  # 'init_arg' is not equal to the field name
  $args{createBackground} = delete $args{cBackground};
  return $class->next::method( %args );
}

sub createBackground {    # $background ($r)
  my ( $self, $r ) = @_;
  assert ( blessed $self );
  assert ( ref $r );
  return $self->{createBackground}->( bounds => $r );
}

1
