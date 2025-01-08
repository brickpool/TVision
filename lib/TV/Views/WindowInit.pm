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
use Params::Check qw(
  check
  last_error
);
use Scalar::Util qw( blessed );

use TV::toolkit;

sub TWindowInit() { __PACKAGE__ }
sub new_TWindowInit { __PACKAGE__->from(@_) }

# declare attributes
has createFrame => ( is => 'bare', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  local $Params::Check::PRESERVE_CASE = 1;
  my $args = STRICT ? check( {
    cFrame => { required => 1, default => sub { }, strict_type => 1 },
  } => { @_ } ) || Carp::confess( last_error ) : { @_ };
  # 'init_arg' is not equal to the field name
  $args->{createFrame} = delete $args->{cFrame};
  return $args;
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
