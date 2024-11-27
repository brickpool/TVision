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

sub new {    # $obj (@|%)
  my $class = shift;
  assert ( $class and !ref $class );
  my $args = $class->BUILDARGS( @_ );
  my $self = {
    items => $args->{items} || undef,
    deflt => $args->{deflt} || $args->{items} || undef,
  };
  bless $self, $class;
  Hash::Util::lock_keys( %$self ) if STRICT;
  return $self;
} #/ sub new

sub BUILDARGS {    # \%args (@|%)
  my $class = shift;
  assert ( $class and !ref $class );

  # predefining %args
  my %args = @_ % 2 ? () : @_;

  # Check @_ for ref, and copy @_ to %args if all entries are ref's
  my @params = qw( items default );
  my $all = grep( ref $_ => @_ ) == @_;
  if ( @_ && $all ) {
    %args = ();
    @args{@params} = @_;
  }

  # 'init_arg' is not the same as the field name.
  $args{deflt} = delete $args{default};

  # 'isa' is undef or TMenuItem
  assert ( !defined $args{items} or blessed $args{items} );
  assert ( !defined $args{deflt} or blessed $args{deflt} );

  return \%args;
}

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
