use 5.014;
use warnings;

BEGIN {
  print "1..0 # Skip win32 required\n" and exit unless $^O =~ /win32|cygwin/i;
  $| = 1;
}

use Test::More tests => 5;

use TurboVision::Drivers::Win32::StdioCtl;

can_ok(
  'TurboVision::Drivers::Win32::StdioCtl',
  qw(
    in
    out
    get_size
    get_font_size
  )
);

my $io = TurboVision::Drivers::Win32::StdioCtl->instance();

isa_ok(
  $io->in,
  'Win32::Console'
);

isa_ok(
  $io->out,
  'Win32::Console'
);

my $size = $io->get_size();
ok (
  $size->{x} > 0 && $size->{y} > 0,
  'StdioCtl->get_size',
);

my $fsize = $io->get_font_size();
ok (
  $fsize,
  'StdioCtl->get_font_size',
);

done_testing;
