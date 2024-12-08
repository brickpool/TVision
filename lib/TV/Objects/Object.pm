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
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw( blessed );

sub TObject() { __PACKAGE__ }

use parent 'UNIVERSAL::Object';

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

1
