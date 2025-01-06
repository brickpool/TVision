package TV::App::DeskInit;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TDeskInit
  new_TDeskInit
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw( blessed );

use TV::toolkit;

sub TDeskInit() { __PACKAGE__ }
sub new_TDeskInit { __PACKAGE__->from(@_) }

# declare attributes
slots createBackground => ( is => 'bare', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%)
  my ( $class, %args ) = @_;
  assert ( $class and !ref $class );
  # 'init_arg' is not equal to the field name
  $args{createBackground} = delete $args{cBackground};
  return \%args;
}

sub from {    # $obj ($cBackground)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 1 );
  return $class->new( cBackground => $_[0] );
}

sub createBackground {    # $background ($r)
  my ( $self, $r ) = @_;
  assert ( blessed $self );
  assert ( ref $r );
  return $self->{createBackground}->( bounds => $r );
}

1
