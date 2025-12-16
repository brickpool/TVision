package TV::Views::CommandSet;
# ABSTRACT: A class for managing command sets in Turbo Vision 2.0.

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

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

my $loc = sub {    # $int ($cmd)
  int( $_[0] / 8 ) % 32;
};

my $mask = sub {    # $int ($cmd)
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

sub from {    # $obj (|$tc)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ >= 0 && @_ <= 1 );
  SWITCH: for ( scalar @_ ) {
    $_ == 0 and return $class->new();
    $_ == 1 and return $class->new( copy_from => $_[0] );
  }
  return;
}

sub clone {    # $clone ()
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

sub isEmpty {    # $bool ()
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

sub include {    # $self ($cmd|$tc)
  my $self = shift;
  assert ( blessed $self );
  $self->enableCmd(@_); 
  return $self;
}

sub exclude {    # $self ($cmd|$tc)
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

sub dump {    # $str ()
  my $self = shift;
  assert ( blessed $self );
  my $dump = "$self=";
  $dump .= join ':' => map { sprintf("%02x", $self->[$_]) } 0 .. 31;
  $dump .= "\n";
  return $dump;
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

__END__

=pod

=head1 NAME

TCommandSet - A class for managing command sets in Turbo Vision 2.0.

=head1 SYNOPSIS

  use TV::Views;

  my $cmdSet = TCommandSet->new();
  $cmdSet->include( $command );
  $cmdSet->disableCmd( $command );
  if ( $cmdSet->contains( $command ) ) {
    print "Command is in the set.\n";
  }

=head1 DESCRIPTION

The C<TCommandSet> class is used to manage sets of commands in Turbo Vision 2.0.
It provides methods to include, exclude, enable, disable, and check commands
within the set. This class is essential for handling user commands and
interactions in a Turbo Vision application.

=head1 METHODS

=head2 new

  my $obj = TCommandSet->new(%args);

Creates a new TCommandSet object.

=over

=item copy_from

Creates a copy of the command set (optional).

=back

=head2 clone

  my $clone = TCommandSet->clone();

Creates a clone of the command set.

=head2 from

  my $obj = TCommandSet->from( | $tc);

Creates a TCommandSet object from another command set.

=head2 disableCmd

  $self->disableCmd($cmd | $tc);

Disables a specific command.

=head2 enableCmd

  $self->enableCmd($cmd | $tc);

Enables a specific command.

=head2 equal

  my $bool = $self->equal($tc1, $tc2);
  '==' => \&equal,

Checks if two command sets are equal.

=head2 exclude

  $self = $self->exclude($cmd | $tc);
  '-=' => \&exclude,

Excludes a specific command from the set.

=head2 has

  my $bool = $self->has($cmd);

Checks if the command set has a specific command.

=head2 include

  $self = $self->include($cmd | $tc);
  # '+=' => \&include;

Includes a specific command in the set.

=head2 intersect

  my $tc = $self->intersect($tc1, $tc2);
  # '&' => \&intersect,

Returns the intersection of two command sets.

=head2 intersect_assign

  my $self = $self->intersect_assign($tc);
  # '&=' => \&intersect_assign,

Assigns the intersection of another command set to the current set.

=head2 isEmpty

  my $bool = $self->isEmpty();

Checks if the command set is empty.

=head2 not_equal

  my $bool = $self->not_equal($tc1, $tc2);
  # '!=' => \&not_equal,

Checks if two command sets are not equal.

=head2 union

  my $tc = $self->union($tc1, $tc2);
  # '|' => \&union,

Returns the union of two command sets.

=head2 union_assign

  $self = $self->union_assign($tc);
  # '|=' => \&union_assign,

Assigns the union of another command set to the current set.

=head1 AUTHORS

=over

=item Turbo Vision Development Team

=item J. Schneider <brickpool@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2025 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution). This documentation is provided under the same terms 
as the Turbo Vision library itself.

=cut
