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

sub BUILDARGS {    # \%args (%)
  my ( $class, %args ) = @_;
  assert ( $class and !ref $class );
  # 'required' arguments
  assert ( defined $args{text} and !ref $args{text} );
  assert ( looks_like_number $args{keyCode} );
  assert ( looks_like_number $args{command} );
  # 'isa' is undef or TStatusItem
  assert ( !defined $args{next} or blessed $args{next} );
  return \%args;
}

sub init {    # $obj ($aText, $key, $cmd, | $aNext)
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ >= 3 && @_ <= 4 );
  return $class->new( 
    text => $_[0], keyCode => $_[1], command => $_[2], next => $_[3]
  );
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
