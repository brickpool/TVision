use strict;
use warnings;

use Test::More tests => 12;
use Test::Exception;

BEGIN {
  use_ok 'Class::LOP';
}

subtest 'Initialization and constructor' => sub {
  my $class;
  lives_ok { $class = Class::LOP->new( 'MyClass' ) } 'Class initialized';
  ok( $class,                     'Class object created' );
  ok( $class->name->can( 'new' ), 'Constructor created' );
};

subtest 'Creating and calling methods and create_method' => sub {
  my $class = Class::LOP->init( 'MyClass' );
  lives_ok { $class->create_method( 'foo', sub { return 'foo' } ) }
    'Method created';
  my $obj = MyClass->new();
  is( $obj->foo(), 'foo', 'Method foo returns foo' );
};

subtest 'strict pragma' => sub {
  my $class = Class::LOP->init( 'MyClass' );
  lives_ok { $class->warnings_strict() } 'Warnings and strict enabled';
  ok( $class->can( 'warnings_strict' ), 'Warnings and strict method exists' );
};

subtest 'Test cases for subclasses and extend_class' => sub {
  my $class = Class::LOP->new( 'ParentClass' );
  my $subclass = Class::LOP->new( 'ChildClass' );

  local $INC{"ParentClass.pm"} = 1;
  $subclass->extend_class( 'ParentClass' );

  my @subclasses = $class->subclasses();
  is_deeply( \@subclasses, ['ChildClass'],
    'ChildClass is a subclass of ParentClass' );
};

subtest 'Test cases for superclasses' => sub {
  my $parent_class = Class::LOP->init( 'ParentClass' );
  my $child_class = Class::LOP->init( 'ChildClass' );

  local $INC{"ParentClass.pm"} = 1;
  $child_class->extend_class( 'ParentClass' );

  my @superclasses = $child_class->superclasses();
  is_deeply( \@superclasses, ['ParentClass'],
    'ParentClass is a superclass of ChildClass' );
};

subtest 'Test cases import_methods' => sub {
  my $class = Class::LOP->init( 'MyClass' );
  can_ok( 'MyClass', 'foo' );
  lives_ok { $class->import_methods( 'ChildClass', 'foo' ) }
    'Method imported';

  my $subclass = Class::LOP->init( 'ChildClass' );
  my $obj = ChildClass->new();
  is( $obj->foo(), 'foo', 'Imported method foo returns foo' );
};

subtest 'Test cases have_accessors' => sub {
  my $class = Class::LOP->init( 'MyClass' );
  lives_ok { $class->have_accessors( 'slot' ) } 'Accessors created';
  can_ok( 'MyClass', 'slot' );
};

subtest 'Test cases add_hook' => sub {
  my $class = Class::LOP->init( 'MyClass' );
  lives_ok {
    $class->add_hook(
      type   => 'after',
      name   => 'foo',
      method => sub { return 'bar' }
      )
  } 'Hook added';
  my $obj = MyClass->new();
  is( $obj->foo(), 'bar', 'Method foo returns bar with hook' );
};

subtest 'Test cases list_methods' => sub {
  my $class = Class::LOP->init( 'MyClass' );
  my @methods = sort grep { /^foo|slot$/ } $class->list_methods();
  is_deeply( \@methods, [ qw( foo slot )], 'List methods returns foo|slot' );
};

subtest 'Test cases clone_object' => sub {
  my $obj = MyClass->new();
  my $clone;
  lives_ok { $clone = Class::LOP->init( $obj )->clone_object() } 
    'Object cloned';
  is_deeply( $obj, $clone, 'Clone object method works correctly' );
};

subtest 'Test cases override_method' => sub {
  my $class = Class::LOP->init( 'MyClass' );
  my $obj = MyClass->new();
  is( $obj->foo(), 'bar', 'Hooked method foo returns bar' );

  lives_ok { $class->override_method( 'foo', sub { return 'baz' } ) }
    'Method overridden';
  is( $obj->foo(), 'baz', 'Overridden method foo returns bar' );
};

done_testing;
