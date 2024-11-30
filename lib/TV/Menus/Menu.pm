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
use Scalar::Util qw(
  blessed
  looks_like_number
);

BEGIN {
  require TV::Objects::Object;
  *mk_constructor = \&TV::Objects::Object::mk_constructor;
  *mk_accessors   = \&TV::Objects::Object::mk_accessors;
}

sub TMenu() { __PACKAGE__ }

# predeclare attributes
use fields qw(
  items
  deflt
);

sub BUILDARGS {    # \%args (%)
  my ( $class, %args ) = @_;
  # 'init_arg' is not the same as the field name.
  $args{deflt} = delete $args{default};
  # 'isa' is undef or TMenuItem
  assert ( !defined $args{items} or blessed $args{items} );
  assert ( !defined $args{deflt} or blessed $args{deflt} );
  return \%args;
}

sub BUILD {    # void (| \%args)
  my $self = shift;
  assert( blessed $self );
  $self->{items} ||= undef;
  $self->{deflt} ||= $self->{items};
  return;
}

sub init {    # $obj (| $itemList, | $TheDefault)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ >= 0 && @_ <= 2 );
  SWITCH: for ( scalar @_ ) {
    $_ == 0 and return $class->new();
    $_ == 1 and return $class->new( items => $_[0], default => $_[0] );
    $_ == 2 and return $class->new( items => $_[0], default => $_[1] );
  }
  return;
}

sub DEMOLISH {    # void ()
  my $self = shift;
  assert( blessed $self );
  while ( $self->{items} ) {
    my $temp = $self->{items};
    $self->{items} = $self->{items}->{next};
    undef $temp;
  }
}

__PACKAGE__
  ->mk_constructor
  ->mk_accessors;

1
