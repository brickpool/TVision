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
use Scalar::Util qw(
  blessed
  looks_like_number
);

BEGIN {
  require TV::Objects::Object;
  *mk_constructor = \&TV::Objects::Object::mk_constructor;
  *mk_accessors   = \&TV::Objects::Object::mk_accessors;
}

sub TStatusItem() { __PACKAGE__ }

# predeclare attributes
use fields qw(
  next
  text
  keyCode
  command
);

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

sub DEMOLISH {    # void ()
  my $self = shift;
  assert( blessed $self );
  undef $self->{text};
  return;
}

__PACKAGE__
  ->mk_constructor
  ->mk_accessors;

1
