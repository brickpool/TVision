package TV::Views::CommandSet;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TCommandSet
  new_TCommandSet
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw(
  blessed
  looks_like_number
);

sub TCommandSet() { __PACKAGE__ }
sub new_TCommandSet { __PACKAGE__->from(@_) }

my $loc = sub {    # $int ( $cmd )
  int( $_[0] / 8 ) % 32;
};

my $mask = sub {    # $int ( $cmd )
  1 << ( $_[0] % 8 );
};

my $disable_cmd = sub {    # void ($cmd)
  my ( $self, $cmd ) = @_;
  $self->[ $loc->( $cmd ) ] &= ~$mask->( $cmd );
  return;
};

my $enable_cmd = sub {    # void ($cmd)
  my ( $self, $cmd ) = @_;
  $self->[ $loc->( $cmd ) ] |= $mask->( $cmd );
  return;
};

my $disable_cmd_set = sub {    # void ($tc)
  my ( $self, $tc ) = @_;
  $self->[$_] &= ~$tc->[$_] for 0 .. 31;
  return;
};

my $enable_cmd_set = sub {    # void ($tc)
  my ( $self, $tc ) = @_;
  $self->[$_] |= $tc->[$_] for 0 .. 31;
  return;
};

sub new {    # $obj (%args)
  my ( $class, %args ) = @_;
  assert ( $class and !ref $class );
  my $self = bless [ ( 0 ) x 32 ], $class;
  @$self = @{ $args{copy_from} }
    if exists $args{copy_from};
  return $self;
} #/ sub new

sub from {    # $obj (| $tc)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ >= 0 && @_ <= 1 );
  SWITCH: for ( scalar @_ ) {
    $_ == 0 and return $class->new();
    $_ == 1 and return $class->new( copy_from => $_[0] );
  }
  return;
}

sub clone {    # $clone ($self)
  my $self = shift;
  assert ( blessed $self );
  my @data = @$self;
  return bless [ @data ], ref $self;
}

sub has {    # $bool ($cmd)
  my ( $self, $cmd ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $cmd );
  return ( $self->[ $loc->( $cmd ) ] & $mask->( $cmd ) ) != 0;
}

sub disableCmd {    # void ($cmd|$tc)
  assert ( blessed $_[0] );
  assert ( ref $_[1] or looks_like_number $_[1] );
  ref $_[1]
    ? goto &$disable_cmd_set
    : goto &$disable_cmd;
}

sub enableCmd {    # void ($cmd|$tc)
  assert ( blessed $_[0] );
  assert ( ref $_[1] or looks_like_number $_[1] );
  ref $_[1]
    ? goto &$enable_cmd_set
    : goto &$enable_cmd;
}

sub isEmpty {    # $bool ($self)
  my $self = shift;
  assert ( blessed $self );
  for ( 0 .. 31 ) {
    return !!0 if $self->[$_] != 0;
  }
  return !!1;
}

sub intersect {    # $tc ($tc1, $tc2)
  my ( $tc1, $tc2 ) = @_;
  assert ( blessed $tc1 );
  assert ( blessed $tc2 );
  my $temp = $tc1->clone();
  $temp->intersect_assign( $tc2 );
  return $temp;
}

sub union {    # $tc ($tc1, $tc2)
  my ( $tc1, $tc2 ) = @_;
  assert ( blessed $tc1 );
  assert ( blessed $tc2 );
  my $temp = $tc1->clone();
  $temp->union_assign( $tc2 );
  return $temp;
}

sub equal {    # $bool ($tc1, $tc2)
  my ( $tc1, $tc2 ) = @_;
  assert ( blessed $tc1 );
  assert ( blessed $tc2 );
  for ( 0 .. 31 ) {
    return !!0 if $tc1->[$_] != $tc2->[$_];
  }
  return !!1;
}

sub not_equal {    # $bool ($tc1, $tc2)
  my ( $tc1, $tc2 ) = @_;
  assert ( blessed $tc1 );
  assert ( blessed $tc2 );
  return !equal( $tc1, $tc2 );
}

sub include {    # void ( $self, $cmd|$tc )
  my $self = shift;
  assert ( blessed $self );
  $self->enableCmd(@_); 
  return $self;
}

sub exclude {    # void ( $self, $cmd|$tc )
  my $self = shift;
  assert ( blessed $self );
  $self->disableCmd(@_);
  return $self;
}

sub intersect_assign {    # $self ($tc)
  my ( $self, $tc ) = @_;
  assert ( blessed $self );
  assert ( blessed $tc );
  $self->[$_] &= $tc->[$_] for 0 .. 31;
  return $self;
}

sub union_assign {    # $self ($tc)
  my ( $self, $tc ) = @_;
  assert ( blessed $self );
  assert ( blessed $tc );
  $self->[$_] |= $tc->[$_] for 0 .. 31;
  return $self;
}

use overload
  '+=' => \&include,
  '-=' => \&exclude,
  '&=' => \&intersect_assign,
  '|=' => \&union_assign,
  '&'  => \&intersect,
  '|'  => \&union,
  '==' => \&equal,
  '!=' => \&not_equal,
  fallback => 1;

1
