=pod

=head1 NAME

TV::Menus::Menu - defines the class TMenu

=cut

package TV::Menus::Menu;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TMenu
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Hash::Util;
use Scalar::Util qw(
  blessed
  looks_like_number
);

sub TMenu() { __PACKAGE__ }

# predeclare attributes
use fields qw(
  items
  deflt
);

sub new {    # $obj (| $itemList, | $TheDefault)
  no warnings 'uninitialized';
  my ( $class, $itemList, $TheDefault ) = @_;
  assert ( $class and !ref $class );
  assert ( !defined $itemList   or blessed $itemList );
  assert ( !defined $TheDefault or blessed $TheDefault );
  my $self = {
    items => $itemList                            || undef,
    deflt => ( @_ > 2 ? $TheDefault : $itemList ) || undef,
  };
  bless $self, $class;
  Hash::Util::lock_keys( %$self ) if STRICT;
  return $self;
} #/ sub new

sub DESTROY {    # void ()
  my $self = shift;
  assert( blessed $self );
  while ( $self->{items} ) {
    my $temp = $self->{items};
    $self->{items} = $self->{items}->{next};
    undef $temp;
  }
}

my $mk_accessors = sub {
  my $pkg = shift;
  no strict 'refs';
  my %FIELDS = %{"${pkg}::FIELDS"};
  for my $field ( keys %FIELDS ) {
    no strict 'refs';
    my $fullname = "${pkg}::$field";
    *$fullname = sub {
      assert( blessed $_[0] );
      $_[0]->{$field} = $_[1] if @_ > 1;
      $_[0]->{$field};
    };
  }
}; #/ $mk_accessors = sub

__PACKAGE__->$mk_accessors();

1
