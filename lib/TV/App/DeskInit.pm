package TV::App::DeskInit;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TDeskInit
  new_TDeskInit
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Params::Check qw(
  check
  last_error
);
use Scalar::Util qw( blessed );

use TV::toolkit;

sub TDeskInit() { __PACKAGE__ }
sub new_TDeskInit { __PACKAGE__->from(@_) }

# declare attributes
has createBackground => ( is => 'bare', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  local $Params::Check::PRESERVE_CASE = 1;
  my $args = STRICT ? check( {
    cBackground => { required => 1, default => sub { }, strict_type => 1 },
  } => { @_ } ) || Carp::confess( last_error ) : { @_ };
  # 'init_arg' is not equal to the field name
  $args->{createBackground} = delete $args->{cBackground};
  return $args;
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
