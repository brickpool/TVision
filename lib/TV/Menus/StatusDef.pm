=pod

=head1 NAME

TV::Menus::StatusDef - defines the class TStatusDef

=cut

package TV::Menus::StatusDef;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TStatusDef
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Hash::Util;
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::Menus::StatusItem;

sub TStatusDef() { __PACKAGE__ }

# predeclare attributes
use fields qw(
  next
  min
  max
  items
);

sub new {    # $obj (@|%)
  no warnings 'uninitialized';
  my $class = shift;
  assert ( $class and !ref $class );
  my $args = $class->BUILDARGS( @_ );
  my $self = {
    next  =>    $args->{next},
    min   => 0+ $args->{min},
    max   => 0+ $args->{max},
    items =>    $args->{items},
  };
  bless $self, $class;
  Hash::Util::lock_keys( %$self ) if STRICT;
  return $self;
}

sub BUILDARGS {    # \%args (@|%)
  my $class = shift;
  assert ( $class and !ref $class );

  # predefining %args
  my %args = @_ % 2 ? () : @_; 

  # Check %args, and copy @_ to %args if 'min' and 'max' are not present
  my @params = qw( min max );
  my $notall = grep( exists $args{$_} => @params ) != @params;
  if ( $notall ) {
    %args = ();
    push @params, qw( items next );    # add optional parameter
    @args{@params} = @_;
  }

  # 'required' arguments
  assert ( looks_like_number $args{min} );
  assert ( looks_like_number $args{max} );

  # check 'isa' (note: 'next' and 'items' can be undefined)
  assert( !defined $args{next}  or blessed $args{next} );
  assert( !defined $args{items} or blessed $args{items} );

  return \%args;
}

sub add_status_item {    # $s1 ($s1, $s2)
	my ( $s1, $s2 ) = @_;
  assert ( blessed $s1 );
  assert ( blessed $s2 and $s2->isa( TStatusItem ) );
	my $def = $s1;
	while ( $def->{next} ) {
		$def = $def->{next};
	}
	if ( !$def->{items} ) {
		$def->{items} = $s2;
	}
	else {
		my $cur = $def->{items};
		while ( $cur->{next} ) {
			$cur = $cur->{next};
		}
		$cur->{next} = $s2;
	}
	return $s1;
} #/ sub add_status_item

sub add_status_def {    # $s1 ($s1, $s2)
	my ( $s1, $s2 ) = @_;
  assert ( blessed $s1 );
  assert ( blessed $s2 and $s2->isa( TStatusDef ) );
	my $cur = $s1;
	while ( $cur->{next} ) {
		$cur = $cur->{next};
	}
	$cur->{next} = $s2;
	return $s1;
}

sub add {    # $s1 ($s1, $s2)
  assert ( blessed $_[0] );
  assert ( blessed $_[1] );
  assert ( not $_[2] );    # test if operands have been swapped
  blessed( $_[1] ) && $_[1]->isa( TStatusDef )
    ? goto &add_status_def
    : goto &add_status_item
}

use overload
  '+' => \&add,
  fallback => 1;

my $mk_accessors = sub {
  my $pkg = shift;
  no strict 'refs';
  my %FIELDS = %{"${pkg}::FIELDS"};
  for my $field ( keys %FIELDS ) {
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
