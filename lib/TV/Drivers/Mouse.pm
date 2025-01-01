package TV::Drivers::Mouse;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TMouse
);

use TV::Drivers::HWMouse;

sub TMouse() { __PACKAGE__ }

use parent THWMouse;

1
