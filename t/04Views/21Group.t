use 5.014;
use warnings;

use Test::More tests => 6;

BEGIN {
  note 'use Objects, Views';
  use_ok 'TurboVision::Objects::Rect';
  use_ok 'TurboVision::Objects::Types', qw( TRect );
  use_ok 'TurboVision::Views::Group';
  use_ok 'TurboVision::Views::Types', qw( TGroup );
}

#-----------------
note 'Constructor';
#-----------------
# init
{
  no strict 'subs';

  my $bounds = TRect->init(0,1,80,24);
  isa_ok($bounds, TRect->class);

  my $group = TGroup->init($bounds);
  isa_ok($group, TGroup->class);
}

done_testing;
