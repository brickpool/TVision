package TV::Objects::Collection;
# ABSTRACT: TCollection provides a mechanism for managing any data collection.

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TCollection
  new_TCollection
);

use TV::Objects::NSCollection;
use TV::toolkit;

sub TCollection() { __PACKAGE__ }
sub name() { 'TCollection' };
sub new_TCollection { __PACKAGE__->from(@_) }

extends TNSCollection;

1

__END__

=pod

=head1 NAME

TV::Objects::Collection - provides a mechanism for managing any data collection.

=head1 DESCRIPTION

In this Perl module, the class I<TCollection> is created, which inherits all the
methods of the TNSCollection class. 

The NS variants of collections are Not Storable.  These are needed for 
internal use in the stream manager.  There are storable variants of each of 
these classes for use by the rest of the library.

=head1 METHODS

The methods I<new>, I<DESTROY>, I<shutDown>, I<at>, I<atRemove>, I<atFree>, 
I<atInsert>, I<atPut>, I<remove>, I<removeAll>, I<free>, I<freeAll>, 
I<freeItem>, I<indexOf>, I<insert>, I<error>, I<firstThat>, I<lastThat>, 
I<forEach>, I<pack> and I<setLimit> have been inherited from TNSCollection.

=head1 AUTHORS

=over

=item Turbo Vision Development Team

=item J. Schneider <brickpool@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2025 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution). This documentation is provided under the same terms 
as the Turbo Vision library itself.

=cut
