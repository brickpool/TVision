=pod

=head1 NAME

TV::Menus::StatusItem - defines the class TStatusItem

=cut

package TV::Menus::StatusItem;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TStatusItem
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Hash::Util;
use Scalar::Util qw(
  blessed
  looks_like_number
);

sub TStatusItem() { __PACKAGE__ }

# predeclare attributes
use fields qw(
  next
  text
  keyCode
  command
);

sub new {    # $obj (@|%)
  no warnings 'uninitialized';
  my $class = shift;
  assert ( $class and !ref $class );
  my $args = $class->BUILDARGS( @_ );
  my $self = {
    text     => ''. $args->{text},
    command  => 0+  $args->{command},
    keyCode  => 0+  $args->{keyCode},
    next     =>     $args->{next},
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

  # Check %args, and copy @_ to %args if 'text'..'command' are not present
  my @params = qw( text keyCode command );
  my $notall = grep( exists $args{$_} => @params ) != @params;
  if ( $notall ) {
    %args = ();
    push @params, 'next';    # add optional parameter
    @args{@params} = @_;
  }

  # 'required' arguments
  assert ( defined $args{text} and !ref $args{text} );
  assert ( looks_like_number $args{keyCode} );
  assert ( looks_like_number $args{command} );

  # 'isa' is undef or TStatusItem
  assert ( !defined $args{next} or blessed $args{next} );

  return \%args;
}

sub DESTROY {    # void ()
  my $self = shift;
  assert( blessed $self );
  undef $self->{text};
  return;
}

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
