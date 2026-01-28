package TV::Objects::StringCollection;
# ABSTRACT: Implement a string collection for the Turbo Vision framework.

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TStringCollection
  new_TStringCollection
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw( blessed );

use TV::Objects::Const qw( ccNotFound );
use TV::Objects::SortedCollection;
use TV::toolkit;

sub TStringCollection() { __PACKAGE__ }
sub name() { 'TStringCollection' };
sub new_TStringCollection { __PACKAGE__->from(@_) }

extends TSortedCollection;

sub compare {    # $cmp ($key1, $key2)
  my ( $self, $key1, $key2 ) = @_;
  assert ( @_ == 3 );
  assert ( blessed $self );
  assert ( defined $key1 and !ref $key1 );
  assert ( defined $key2 and !ref $key2 );
  return $key1 <=> $key2;
}

1

__END__

=pod

=head1 NAME

TStringCollection - implement a string collection for Turbo Vision.

=head1 DESCRIPTION

In this Perl module, the class I<TStringCollection> is created, which inherits
from I<TSortedCollection>. 

=head2 Methods

The method I<compare> has been overridden to suit the comparison of strings. 
Otherwise, all methods have been adopted unchanged from the parent classes.

=head1 AUTHORS

=over

=item Turbo Vision Development Team

=item J. Schneider <brickpool@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
