use 5.014;
use warnings;
use Test::More;

use TurboVision::Objects::Types qw(
  TPoint
  TRect
);

#------------
note 'TPoint';
#------------
use_ok 'TurboVision::Objects::Point';

my $pt = TPoint->new(x => 1, y => 2);
isa_ok( $pt, TPoint->class );

my $a = $pt + $pt;
my $d = $pt - $pt;

$a -= $pt;
$d += $pt;

is(
  $a->x, $d->x,
  'TPoint->_sub && TPoint->_add && TPoint->a->x'
);

is(
  $a->y, $d->y,
  'TPoint->_sub && TPoint->_add && TPoint->a->y'
);

cmp_ok(
  $a, '==', $d,
  'TPoint->_equal'
);

ok(
  !($a != $d),
  'TPoint->_not_equal'
);

ok( length($a) > 15, 'TPoint->_stringify' );

#------------
note 'TRect';
#------------
use_ok 'TurboVision::Objects::Rect';

my $r = TRect->init(1, 2, 3, 4);
isa_ok( $r, TRect->class );

is( $r->a->x, 1, 'TRect->a->x' );
is( $r->a->y, 2, 'TRect->a->y' );
is( $r->b->x, 3, 'TRect->b->x' );
is( $r->b->y, 4, 'TRect->b->y' );

ok( $r->contains($a), 'TRect->contains' );

my $z = TRect->new;
ok( $z->empty(), 'TRect->empty' );

$z->copy($r);
ok    ( $z->equals($r), 'TRect->equals'     );
cmp_ok( $z, '==', $r,   'TRect->_equal'     );
ok    ( !( $z != $r ),  'TRect->_not_equal' );

$r->move(1, 2);
$r->grow(0, 1);
$z->assign(2, 3, 4, 7);
cmp_ok(
  $r, '==', $z,
  'TRect->move && TRect->grow && TRect->assign'
);

ok( length($r) > 30, 'TRect->_stringify' );

done_testing;
