package TV::Dialogs::StrItem;
# ABSTRACT: Simple singly linked list node for Turbo Vision dialog data

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TSItem
  new_TSItem
);

use Devel::StrictMode;
use if STRICT => 'Hash::Util';
use TV::toolkit qw( :utils );
use TV::toolkit::Types qw(
  Maybe
  :is
  :types
);

sub TSItem() { __PACKAGE__ }
sub new_TSItem { __PACKAGE__->from(@_) }

# public attributes
our %HAS; BEGIN {
  %HAS = (
    value => sub { '' },
    next  => sub { undef },
  );
}

sub new {    # \$item (%args)
  state $sig = signature(
    method => 1,
    named  => [
      value => Str,
      next  => Maybe[Object],
    ],
  );
  my ( $class, $self ) = $sig->( @_ );
  bless $self, $class;
  Hash::Util::lock_keys( %$self ) if STRICT;
  return $self;
}

sub from {    # $item ($aValue, $aNext|undef)
  state $sig = signature(
    method => 1,
    pos    => [Str, Maybe[Object]],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( value => $args[0], next => $args[1] );
}

my $mk_ro_accessors = sub {
  my ( $pkg ) = @_;
  assert ( @_ == 1 );
  assert ( defined $pkg );
  no strict 'refs';
  my %HAS = %{"${pkg}::HAS"};
  for my $field ( keys %HAS ) {
    my $full_name = "${pkg}::$field";
    *$full_name = sub {
      assert ( @_ == 1 );
      assert ( is_Object $_[0] );
      $_[0]->{$field};
    };
  }
};

__PACKAGE__->$mk_ro_accessors();

1;

__END__

=pod

=head1 NAME

TSItem - simple singly linked list node for Turbo Vision dialog data

=head1 SYNOPSIS

  use TV::Dialogs;

  my $item3 = TSItem->new("third", undef);
  my $item2 = TSItem->new("second", $item3);
  my $item1 = TSItem->new("first",  $item2);

  my $value = $item1->value;      # "first"
  my $next  = $item1->next;       # $item2

=head1 DESCRIPTION

C<TSItem> represents a simple singly linked list node used for storing 
dialog-related data.  

Each node contains a string value and a reference to the next node or C<undef>.  
The structure mirrors the original Turbo Vision C++ TSItem class, but uses 
Perl's automatic memory management.  

It is typically used internally by higher-level dialog controls and support code.

=head1 ATTRIBUTES

=over

=item value

The current string value held by this list node (I<Str>).

=item next

The reference to the next node in the singly linked list, or C<undef> 
(I<TSItem> or undef).

=back

=head1 METHODS

=head2 new

  my $item = TSItem->new(value => $value, next => $next);

Creates a new C<TSItem> node with the given value and link to the next node.

=over

=item value

The string value stored in the node (I<Str>).

=item next

Reference to the next C<TSItem> in the list or C<undef> (I<TSItem> or undef).

=back

=head2 new_TSItem

  my $item = new_TSItem($aValue, $aNext | undef);

Factory constructor that instantiates a string element from a value and the 
next list element (I<TSItem> or undef).

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
