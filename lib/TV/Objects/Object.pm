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

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw( blessed );

use TV::toolkit;

sub TObject() { __PACKAGE__ }

use fields qw();

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

sub mk_constructor {
  my $this = shift;
  TV::toolkit::create_constructor( $this, @_ );
  return $this;    # for chaining
}

sub mk_accessors {
  my $this = shift;
  TV::toolkit::install_slots( $this, @_ );
  return $this;    # for chaining
}

__PACKAGE__->mk_constructor();

1
