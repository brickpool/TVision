=pod

=head1 NAME

TV::Objects::Object - defines the class TObject

=cut

package TV::Objects::Object;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TObject
);

use Carp ();
use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw( blessed );
use mro ();

sub TObject() { __PACKAGE__ }

use fields qw();

my $EINVAL = do {
  require Errno;
  local $! = 1;
  $! = &Errno::EINVAL if exists &Errno::EINVAL;
  "$!";
};

sub new {    # $obj (@)
  my $self  = shift;
  my $class = ref $self || $self;
  $self = fields::new( $class ) unless ref $self;
  {
    no strict 'refs';
    map {
      my $pkg   = ref $_ || $_;
      my $build = "$pkg\::BUILD";
      $build->( $self, @_ ) if exists( &$build )
    } reverse @{ mro::get_linear_isa( $class ) };
  }
  return $self;
} #/ sub new

sub DESTROY {    # void ($self)
  assert ( blessed shift );
  return;
}

sub destroy {    # void ($class|$self, $o|undef)
  my $class = shift;
  assert ( $class );
  if ( defined $_[0] ) {
    assert ( blessed $_[0] );
    $_[0]->shutDown();
    undef $_[0];
  }
  return;
}

sub shutDown {    # void ($self)
  assert ( blessed shift );
  return;
}

my $_mk_accessors = sub {
  my ( $this, $access, @fields ) = @_;
  my $pkg = ref $this || $this;
  $access ||= 'rw';
  @fields = fields::_accessible_keys( $pkg ) unless @fields;
  for my $field ( @fields ) {
    next if $pkg->can( $field );
    no strict 'refs';
    my $fullname = "${pkg}::$field";
    *$fullname =
      $access eq 'ro'
      ? sub { 
          Carp::croak( $EINVAL ) if @_ > 1;
          $_[0]->{$field};
        }
      : sub { 
          $_[0]->{$field} = $_[1] if @_ > 1; 
          $_[0]->{$field};
        };
  }
}; #/ $_mk_accessors = sub

sub mk_ro_accessors {
  shift->$_mk_accessors( 'ro', @_ );
}

sub mk_rw_accessors {
  shift->$_mk_accessors( 'rw', @_ );
}

{
  no warnings 'once';
  *mk_accessors = \&mk_rw_accessors;
}

1
