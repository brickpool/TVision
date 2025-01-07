package TV::Views::WindowInit;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TWindowInit
  new_TWindowInit
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw( blessed );

use TV::toolkit;

sub TWindowInit() { __PACKAGE__ }
sub new_TWindowInit { __PACKAGE__->from(@_) }

# declare attributes
has createFrame => ( is => 'bare', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%)
  my ( $class, %args ) = @_;
  assert ( $class and !ref $class );
  # 'init_arg' is not equal to the field name
  $args{createFrame} = delete $args{cFrame};
  return \%args;
}

sub from {    # $obj ($cFrame)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 1 );
  return $class->new( cFrame => $_[0] );
}

sub createFrame {    # $frame ($r)
  my ( $self, $r ) = @_;
  assert ( blessed $self );
  assert ( ref $r );
  return $self->{createFrame}->( bounds => $r );
}

1
