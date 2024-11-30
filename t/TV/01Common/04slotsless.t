use strict;
use warnings;

use Test::More tests => 11;
use Test::Exception;

BEGIN {
  require_ok 'UNIVERSAL::Object';
  require_ok 'base';
  require_ok 'fields';
  use_ok 'slots::less';
}

BEGIN {
  package Point;
  use strict;
  use warnings;
  use base 'UNIVERSAL::Object';
  use slots::less (
    x => sub { 0 },
    y => sub { 0 },
  );
  no slots::less;
  sub clear {
	  my ( $self ) = @_;
    $self->{x} = 0;
    $self->{y} = 0;
  }
  $INC{"Point.pm"} = 1;
}

BEGIN { 
  package Point3D;
  use strict;
  use warnings;
  use base 'Point';
  use slots::less (
    z => sub { 0 },
  );
  sub clear {
	  my ( $self ) = @_;
    $self->next::method;
    $self->{z} = 0;
  }
  $INC{"Point3D.pm"} = 1;
}

use_ok 'Point';
use_ok 'Point3D';

is_deeply(
  [ sort keys %Point::HAS ], 
  [ sort keys %Point::FIELDS ], 
  'keys %Point::HAS is equal to keys %Point::FIELDS'
);
is_deeply(
  [ sort keys %Point3D::HAS ],
  [ sort keys %Point3D::FIELDS ],
  'keys %Point3D::HAS is equal to keys %Point3D::FIELDS'
);
my $point = Point3D->new( attr4 => 4 );
isa_ok( $point, 'UNIVERSAL::Object' );
lives_ok { $point->z } 'Access to attribute works correctly';

is_deeply(
  [ sort keys %$point ],
  [ sort keys %Point3D::FIELDS ],
  'keys %Point3D::HAS is equal to keys %$point'
);

require slots::less;
note 'Class::XSAccessor: ', slots::less::XS ? 1 : 0;

no strict 'refs';
while ( my ( $name, $symbol ) = each %{'Point::'} ) {
	next if $name eq 'BEGIN'         # don't print BEGIN blocks
	     || $name eq 'import';       # don't print this sub
	next unless *{$symbol}{CODE};    # print subs only
	note $symbol;
}
while ( my ( $name, $symbol ) = each %{'Point3D::'} ) {
	next if $name eq 'BEGIN'
	     || $name eq 'import';
	next unless *{$symbol}{CODE};
	note $symbol;
}

done_testing();
