package TV::Menus::Menu;
# ABSTRACT: Linked list of TMenuItem records

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TMenu
  new_TMenu
);

use Devel::StrictMode;
use Scalar::Util qw( weaken );
use TV::toolkit;
use TV::toolkit::Types qw(
  Maybe
  is_Object
  :types
);

sub TMenu() { __PACKAGE__ }
sub new_TMenu { __PACKAGE__->from(@_) }

# public attributes
has items => ( is => 'rw' );
has deflt => ( is => 'bare' );    # weak_ref => 1

my $lock_value = sub {
  Internals::SvREADONLY( $_[0] => 1 )
    if exists &Internals::SvREADONLY;
};

my $unlock_value = sub {
  Internals::SvREADONLY( $_[0] => 0 )
    if exists &Internals::SvREADONLY;
};

sub BUILDARGS {    # \%args (|%args)
  state $sig = signature(
    method => 1,
    named  => [
      items => Object, { optional => 1, },
      deflt => Object, { optional => 1, alias => 'default' },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{deflt} //= $self->{items};
  weaken $self->{deflt} if $self->{deflt};
  &$lock_value( $self->{deflt} ) if STRICT;
  return;
}

sub from {    # $obj (| $itemList, | $TheDefault)
  state $sig = signature(
    method => 1,
    pos => [
      Object, { optional => 1 },
      Object, { optional => 1 },
    ],
  );
  my ( $class, @args ) = $sig->( @_ );
  SWITCH: for ( scalar @args ) {
    $_ == 0 and return $class->new();
    $_ == 1 and return $class->new( items => $args[0], default => $args[0] );
    $_ == 2 and return $class->new( items => $args[0], default => $args[1] );
  }
  return;
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  while ( $self->{items} ) {
    my $temp = $self->{items};
    $self->{items} = $self->{items}{next};
    undef $temp;
  }
  &$unlock_value( $self->{deflt} ) if STRICT;
  return;
}

sub deflt {    # $view|undef (|$view|undef)
  state $sig = signature(
    method => Object,
    pos    => [
      Maybe[Object], { optional => 1 },
    ],
  );
  my ( $self, $view ) = $sig->( @_ );
  goto SET if @_ > 1;
  GET: {
    return $self->{deflt};
  }
  SET: {
    &$unlock_value( $self->{deflt} ) if STRICT;
    weaken $self->{deflt}
      if $self->{deflt} = $view;
    &$lock_value( $self->{deflt} ) if STRICT;
    return;
  }
}

1

__END__

=pod

=head1 NAME

TV::Menus::Menu - defines the class TMenu

=cut
