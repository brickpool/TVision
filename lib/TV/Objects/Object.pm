package TV::Objects::Object;
# ABSTRACT: defines the class TObject

use 5.010;
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
use Scalar::Util qw(
  weaken
  isweak
);
use TV::toolkit;
use TV::toolkit::Types qw(
  Maybe
  :is
  :types
);

sub TObject() { __PACKAGE__ }
sub new_TObject { __PACKAGE__->from(@_) }

my $unlock_value = sub {
  Internals::SvREADONLY( $_[0] => 0 )
    if exists &Internals::SvREADONLY;
};

sub BUILDARGS {    # \%args ()
  state $sig = signature(
    method => 1,
    named  => [],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return $args ? { %$args } : {};
}

sub from {    # $obj ();
  state $sig = signature(
    method => 1,
    pos => [],
  );
  my ( $class ) = $sig->( @_ );
  return $class->new();
}

sub destroy {    # void ($class|$self, $o|undef)
  my ( $class, $o ) = @_;
  assert ( defined $class );
  assert ( !defined $o or is_Object $o );
  $class = ref $class || $class;
  alias: for $o ( $_[1] ) {
  if ( defined $o ) {
    assert ( is_Object $o );
    $o->shutDown();
    for ( keys %$o ) {
      if ( ref $o->{$_} && !isweak $o->{$_} ) {
        &$unlock_value( $o->{$_} ) if STRICT;
        weaken $o->{$_};
      }
    }
    undef $o;
  }
  return;
  } #/ alias
}

sub shutDown {    # void ($self)
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  $sig->( @_ );
  return;
}

1

__END__

=pod

=head1 AUTHORS

=over

=item Turbo Vision Development Team

=item J. Schneider <brickpool@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution). This documentation is provided under the same terms 
as the Turbo Vision library itself.

=cut
