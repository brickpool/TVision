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

use Carp ();
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
has createBackground => ( is => 'bare' );

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  local $Params::Check::PRESERVE_CASE = 1;
  my $args = check( {
    cBackground => {
      required    => 1, 
      defined     => 1, 
      default     => sub { }, 
      strict_type => 1,
    },
  } => { @_ } ) || Carp::confess( last_error );
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
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( ref $r );
  my ( $class, $code ) = ( ref $self, $self->{createBackground} );
  return $class->$code( $r );
}

1
