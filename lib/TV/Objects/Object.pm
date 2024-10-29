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

sub TObject() { __PACKAGE__ }

sub new {    # $obj ($class)
  my $class = shift;
  my $self  = bless {}, $class;
  return $self;
}

sub DESTROY {    # void ($self)
  return;
}

sub destroy {    # void ($class)
  my $class = shift;
  if ( defined $_[0] ) {
    $_[0]->shutDown();
    undef $_[0];
  }
}

sub shutDown {    # void ($self)
  return;
}

1
