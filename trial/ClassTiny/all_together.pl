BEGIN {
  package Devel::Assert::More;

  use strict;
  use warnings;
  
  use Exporter 'import';

  our @EXPORT_OK = qw(
    assert_Object
    assert_Int
  );

  use Carp qw( croak );
  use Devel::StrictMode;
  use Type::Nano qw( 
    Object
    Int
  );

  $Carp::CarpInternal{ (__PACKAGE__) }++;

  sub assert_Object($) {
    STRICT && Object->check($_[0]) 
      or croak(Object->get_message($_[0]));
    $_[0];
  }

  sub assert_Int($) {
    STRICT && Int->check($_[0]) 
      or croak(Int->get_message($_[0]));
    $_[0];
  }

  $INC{"Devel/Assert/More.pm"} = 1;
}

BEGIN {
  package Object;

  use strict;
  use warnings;
  use namespace::sweep;

  use Class::Tiny::Antlers;
  use Function::Parameters qw(
    method
    classmethod
  );

  our %FIELDS = ();

  # disallow setting the attribute on undefined 'init_arg'
  classmethod BUILDARGS ( %args ) {
    $FIELDS{$class} //= do {
      # no warnings 'uninitialized'
      local $SIG{__WARN__} = sub { warn $_[0] if $_[0] !~ /uninitialized/ };
      Class::Tiny::Antlers->get_all_attribute_specs_for( $class );
    };
    delete $args{$_} for grep {                           # delete argument
           exists $args{$_}                               # ..when valid
        && exists $FIELDS{$class}->{$_}->{init_arg}       # ..and init_args
        && ref    $FIELDS{$class}->{$_}->{init_arg}       # ..is \undef
      } keys %{$FIELDS{$class}};
    return { %args };
  }

  # set values for 'default' at 'bare', because 'bare' is not 'lazy'
  method BUILD ( @ ) {
    my $class = ref $self;
    $FIELDS{$class} //= do {
      # no warnings 'uninitialized'
      local $SIG{__WARN__} = sub { warn $_[0] if $_[0] !~ /uninitialized/ };
      Class::Tiny::Antlers->get_all_attribute_specs_for( $class );
    };
    foreach ( 
      grep {
          !defined($self->{$_})                           # attr not defined
        && $FIELDS{$class}->{$_}->{is} eq 'bare'          # attr is bare
        && exists($FIELDS{$class}->{$_}->{default})       # attr has default
      } keys %{$FIELDS{$class}}
    ) {
      $self->{$_} = ref($FIELDS{$class}->{$_}->{default}) eq 'CODE' 
        ? $FIELDS{$class}->{$_}->{default}->()            # default => sub { }
        : $FIELDS{$class}->{$_}->{default}                # default => ...
    }
  }

  $INC{"Object.pm"} = 1;
}

BEGIN {
  package Point;

  use strict;
  use warnings;
  use namespace::sweep;

  use Class::Tiny::Antlers;
  use Devel::Assert::More qw( /^assert/ );
  use Sentinel;
  use Type::Nano qw( Int );

  extends 'Object';

  { 
    # no warnings 'uninitialized'
    local $SIG{__WARN__} = sub { warn $_[0] if $_[0] !~ /uninitialized/ };
    has x => ( is => 'bare', default => sub { 0 }, init_arg => \undef );
    has y => ( is => 'bare', isa => Int );
  }

  sub x :lvalue {
    my $self = assert_Object shift; 
    sentinel
      get => sub {
        return $self->{x}
      }, 
      set => sub {
        $self->{x} = assert_Int shift;
      }
  }

  sub y :lvalue {
    my $self = assert_Object shift;
    sentinel
      get => sub {
        return $self->{y}
      }, 
      set => sub {
        $self->{y} = assert_Int shift;
      }
  }

  $INC{"Point.pm"} = 1;
}

BEGIN {
  package Point3D;

  use strict;
  use warnings;
  use namespace::sweep;

  use Class::Tiny::Antlers;
  use Type::Nano qw( Int );

  extends 'Point';

  has z => ( is => 'rw', isa => Int, default => 3 );

  $INC{"Point3D.pm"} = 1;
}

package main;

use Point3D;

my $pt = Point3D->new( x => 1, y => '2a' );

printf("x:%s, y:%s, z:%s\n", $pt->x, $pt->y, $pt->z);

$pt->x = 2;
$pt->y++;
$pt->z( 4 );

printf("x:%s, y:%s, z:%s\n", @$pt{'x'..'z'});
