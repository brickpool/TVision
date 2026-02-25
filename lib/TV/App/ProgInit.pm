package TV::App::ProgInit;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TProgInit
  new_TProgInit
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

sub TProgInit() { __PACKAGE__ }
sub new_TProgInit { __PACKAGE__->from(@_) }

# declare attributes
has createStatusLine => ( is => 'bare' );
has createMenuBar    => ( is => 'bare' );
has createDeskTop    => ( is => 'bare' );

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  local $Params::Check::PRESERVE_CASE = 1;
  my $args = check( {
    cStatusLine => {
      required    => 1, 
      defined     => 1, 
      default     => sub { }, 
      strict_type => 1,
    },
    cMenuBar    => {
      required    => 1, 
      defined     => 1, 
      default     => sub { }, 
      strict_type => 1,
    },
    cDeskTop    => {
      required    => 1, 
      defined     => 1, 
      default     => sub { }, 
      strict_type => 1,
    },
  } => { @_ } ) || Carp::confess( last_error );
  # 'init_arg' is not equal to the field name
  $args->{createStatusLine} = delete $args->{cStatusLine};
  $args->{createMenuBar}    = delete $args->{cMenuBar};
  $args->{createDeskTop}    = delete $args->{cDeskTop};
  return $args;
} #/ sub BUILDARGS

sub from {    # $obj ($cStatusLine, $cMenuBar, $cDeskTop)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 3 );
  return $class->new(
    cStatusLine => $_[0],
    cMenuBar    => $_[0],
    cDeskTop    => $_[0],
  );
}

sub createStatusLine {    # $statusLine ($r)
  my ( $self, $r ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( ref $r );
  my ( $class, $code ) = ( ref $self, $self->{createStatusLine} );
  return $class->$code( $r );
}

sub createMenuBar {    # $menuBar ($r)
  my ( $self, $r ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( ref $r );
  my ( $class, $code ) = ( ref $self, $self->{createMenuBar} );
  return $class->$code( $r );
}

sub createDeskTop {    # $deskTop ($r)
  my ( $self, $r ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( ref $r );
  my ( $class, $code ) = ( ref $self, $self->{createDeskTop} );
  return $class->$code( $r );
}

1
