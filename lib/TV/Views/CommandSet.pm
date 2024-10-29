package TV::Views::CommandSet;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TCommandSet
);

use TV::Views::Const qw(
  CM_ZOOM
  CM_CLOSE
  CM_RESIZE
  CM_NEXT
  CM_PREV
);

sub TCommandSet() { __PACKAGE__ }

my $loc = sub {    # $int ( $cmd )
  return int( $_[0] / 8 );
};

my $mask = sub {    # $int ( $cmd )
  return 1 << ( $_[0] % 8 );
};

my $disable_cmd = sub {    # void ($self, $cmd)
  my ( $self, $cmd ) = @_;
  $self->[ $loc->( $cmd ) ] &= ~$mask->( $cmd );
  return;
};

my $enable_cmd = sub {    # void ($self, $cmd)
  my ( $self, $cmd ) = @_;
  $self->[ $loc->( $cmd ) ] |= $mask->( $cmd );
  return;
};

my $disable_cmd_set = sub {    # void ($self, $tc)
  my ( $self, $tc ) = @_;
  $self->[$_] &= ~$tc->[$_] for 0 .. 31;
  return;
};

my $enable_cmd_set = sub {    # void ($self, $tc)
  my ( $self, $tc ) = @_;
  $self->[$_] |= $tc->[$_] for 0 .. 31;
  return;
};

sub new {    # $obj ($class, %args)
  my ( $class, %args ) = @_;
  my $self = bless [ ( 0 ) x 32 ], $class;
  @$self = @{ $args{copy_from} }
    if exists $args{copy_from};
  return $self;
} #/ sub new

sub clone {    # $clone ($self)
  my ( $self ) = @_;
  my @data = @$self;
  return bless [ @data ], ref $self;
}

sub has {    # $bool ($self, $cmd)
  my ( $self, $cmd ) = @_;
  return ( $self->[ $loc->( $cmd ) ] & $mask->( $cmd ) ) != 0;
}

sub disableCmd {    # void ($self, $cmd|$tc)
  ref $_[1]
    ? goto &$disable_cmd_set
    : goto &$disable_cmd;
}

sub enableCmd {    # void ($self, $cmd|$tc)
  ref $_[1]
    ? goto &$enable_cmd_set
    : goto &$enable_cmd;
}

sub isEmpty {    # $bool ($self)
  my ( $self ) = @_;
  for ( 0 .. 31 ) {
    return !!0 if $self->[$_] != 0;
  }
  return !!1;
}

sub intersect {    # $tc ($tc1, $tc2)
  my ( $tc1, $tc2 ) = @_;
  my $temp = $tc1->clone();
  $temp->intersect_assign( $tc2 );
  return $temp;
}

sub union {    # $tc ($tc1, $tc2)
  my ( $tc1, $tc2 ) = @_;
  my $temp = $tc1->clone();
  $temp->union_assign( $tc2 );
  return $temp;
}

sub equal {    # $bool ($tc1, $tc2)
  my ( $tc1, $tc2 ) = @_;
  for ( 0 .. 31 ) {
    return !!0 if $tc1->[$_] != $tc2->[$_];
  }
  return !!1;
}

sub not_equal {    # $bool ($tc1, $tc2)
  my ( $tc1, $tc2 ) = @_;
  return !equal( $tc1, $tc2 );
}

sub include {    # void ( $self, $cmd|$tc )
  goto &enableCmd;
}

sub exclude {    # void ( $self, $cmd|$tc )
  goto &disableCmd;
}

sub intersect_assign {    # $bool ($self, $tc)
  my ( $self, $tc ) = @_;
  $self->[$_] &= $tc->[$_] for 0 .. 31;
  return $self;
}

sub union_assign {    # $bool ($self, $tc)
  my ( $self, $tc ) = @_;
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
