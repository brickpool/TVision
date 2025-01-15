use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  unless ( eval { require UNIVERSAL::Object } ) {
    plan skip_all => 'Test irrelevant without Universal::Object';
  }
  else {
    plan tests => 11;
  }
  require_ok 'UNIVERSAL::Object';
  use_ok 'slots::less';
}

BEGIN {
  package Point;
  use parent 'UNIVERSAL::Object';
  use slots::less (
    x => sub { 0 },
    y => sub { 0 },
  );
  $INC{"Point.pm"} = 1;
}

BEGIN {
  package Point3D;
  use parent 'Point';
  use slots::less (
    z => sub { 0 },
  );
  $INC{"Point3D.pm"} = 1;
}

BEGIN {
  package Derived;
  use parent 'Point';
  use slots::less;
  $INC{"Derived.pm"} = 1;
}

my ( %accessors, $next );

use_ok 'Point';
use_ok 'Derived';
{
  no strict 'refs';
  while ( my ( $name, $symbol ) = each %{'Point::'} ) {
    next unless *{$symbol}{CODE};    # print subs only
    $accessors{$name} = ++$next;
  }
  is_deeply(
    [ sort keys %Point::HAS ], 
    [ sort keys %accessors ], 
    'keys %Point::HAS is equal to accessors'
  );
  is_deeply(
    [ sort keys %Derived::HAS ], 
    [ sort keys %Point::HAS ], 
    'keys %Derived::HAS is equal to accessors'
  );
}

use_ok 'Point3D';
{
  no strict 'refs';
  while ( my ( $name, $symbol ) = each %{'Point3D::'} ) {
    next unless *{$symbol}{CODE};    # print subs only
    $accessors{$name} = ++$next;
  }
  is_deeply(
    [ sort keys %Point3D::HAS ],
    [ sort keys %accessors ],
    'keys %Point3D::HAS is equal to accessors'
  );
}

{
  my $point = Point3D->new( attr4 => 4 );
  isa_ok( $point, 'UNIVERSAL::Object' );
  lives_ok { $point->z } 'Access to attribute works correctly';

  is_deeply(
    [ sort keys %$point ],
    [ sort keys %accessors ],
    'keys %Point3D::HAS is equal to fields'
  );
}

require slots::less;
note 'Class::XSAccessor: ', slots::less::XS ? 1 : 0;

done_testing();
