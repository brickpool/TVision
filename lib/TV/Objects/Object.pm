=pod

=head1 NAME

TV::Objects::Object - defines the class TObject

=cut

package TV::Objects::Object;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TObject
  new_TObject
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw(
  blessed
  reftype
);

use TV::toolkit;

sub TObject() { __PACKAGE__ }
sub new_TObject { __PACKAGE__->from(@_) }

sub from {    # $obj ();
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ == 0 );
  return $class->new();
}

sub destroy {    # void ($class|$self, $o|undef)
  my $class = ref $_[0] || $_[0];
  alias: for my $o ( $_[1] ) {
  assert ( $class );
  if ( defined $o ) {
    assert ( blessed $o );
    $o->shutDown();
    undef $o;
  }
  return;
  } #/ alias
}

sub shutDown {    # void ($self)
  assert ( blessed $_[0] );
  return;
}

1
