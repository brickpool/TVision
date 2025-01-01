=pod

=head1 NAME

Cursor

=cut

use 5.014;
use warnings;
use Test::More tests => 15;
use Test::Exception;

=head1 DESCRIPTION

=head2 Class

static class I<< Cursor >>

Object Hierarchy

  Moose::Object
    Cursor

=cut

package Hardware::Cursor {
  use Function::Parameters {
    static => {
      defaults => 'classmethod_strict',
      shift    => '$caller',
    }
  };
  use Moose;
  use MooseX::Types::Moose qw( Int Object Maybe );
  use namespace::autoclean;

=head2 Attributes

=cut

  %::__PACKAGE__ = ();

=over

=item I<x>

  static 'x' => (
    is        => 'rw',
    isa       => Int,
    init_arg  => undef,
    default   => 0,
  );

Cursor I<x>.

=cut

  __PACKAGE__->{x} = do {
    ACCESSOR:
    static x(Maybe[Int] $value=) {
      goto SET if @_;
      GET: {
        return __PACKAGE__->{x};
      }
      SET: {
        return __PACKAGE__->{x} = $value;
      }
    }
    DEFAULT: {
      0
    }
  };

=item I<y>

  static 'y' => (
    is        => 'rw',
    isa       => Int,
    init_arg  => undef,
    default   => 0,
  );

Cursor I<y>.

=cut

  __PACKAGE__->{y} = do {
    ACCESSOR:
    static y(Maybe[Int] $value=) {
      goto SET if @_;
      GET: {
        return __PACKAGE__->{y};
      }
      SET: {
        return __PACKAGE__->{y} = $value;
      }
    }
    DEFAULT: {
      0
    }
  };

=item I<type>

  static 'type' => (
    is        => 'ro',
    isa       => Int,
    init_arg  => undef,
    writer    => '_type',
  );

Cursor I<type>.

=cut

  __PACKAGE__->{type} = do {
    READER:
    static type() {
      return __PACKAGE__->{type};
    }
    WRITER:
    static _type(Maybe[Int] $value=) {
      return __PACKAGE__->{type} = $value;
    }
    DEFAULT: {
      undef
    }
  };

=item I<valid>

  static 'valid' => (
    is        => 'ro',
    isa       => Bool,
    init_arg  => undef,
    lazy      => 1,
    builder   => '_build_valid',
  );

Cursor I<valid>.

=cut

  # __PACKAGE__->{valid} = do
  {
    READER:
    static valid() {
      BUID: {
        __PACKAGE__->{valid} = $caller->_build_valid
          unless exists __PACKAGE__->{valid};
      }
      return __PACKAGE__->{valid};
    }
    BUILDER:
    static _build_valid() {
      return !!1;
    }
    DEFAULT: {
      undef
    }
  }

=back

=head2 Methods

=over

=item I<copy>

  static copy(Object $pt)

Copy I<$pt>.

=cut

  # Adopted from the C++ Turbo Vision library
  static copy( Object $pt ) {
    $caller->x( $pt->x );
    $caller->y( $pt->y );
  }

=back

=cut

  __PACKAGE__->meta->make_immutable;
  1;
}

# Alias for the package name
use constant TCursor => 'Hardware::Cursor';

BEGIN {
  use_ok 'Hardware::Cursor';
}

INIT {
  ok(
    !(exists $Hardware::Cursor{valid}),
    'Not exists: TCursor->{valid}'
  );
  lives_ok(
    sub{ TCursor->valid() },
    'Lives: TCursor->_build_valid && TCursor->valid'
  );
  ok(
    exists $Hardware::Cursor{valid},
    'Exists: TCursor->{valid}'
  );
}

ok(
  defined TCursor->x,
  'Get: TCursor->x'
);
is(
  TCursor->y,
  0,
  'Default: TCursor->y == 0'
);
lives_ok(
  sub { TCursor->y(1) },
  'Set: TCursor->y(1)'
);
is(
  TCursor->y,
  1,
  'Get: TCursor->y == 1'
);
dies_ok(
  sub { TCursor->type(1) },
  'Set dies: TCursor->type(1)'
);
is(
  TCursor->type,
  undef,
  'Not defined: TCursor->type'
);
lives_ok(
  sub { TCursor->_type(1) },
  'Set: TCursor->type(1)'
);
is(
  TCursor->type,
  1,
  'Get: TCursor->type == 1'
);
is(
  ( TCursor->{valid} = !!0 ),
  !!0,
  'Set direct: TCursor->{valid} = FALSE'
);
ok(
  !TCursor->valid(),
  'Builder not fire: TCursor->valid'
);
TCursor->copy( TCursor->new() );
is(
  TCursor->y,
  1,
  'Static method: TCursor->copy'
);

done_testing();
