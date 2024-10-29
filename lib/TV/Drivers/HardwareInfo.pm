package TV::Drivers::HardwareInfo;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw( THardwareInfo );

# Code snippet taken from File::Spec
my %module = (
  MSWin32 => 'Win32',
);

my $module = $module{$^O} || 'Unix';

sub THardwareInfo() { "TV::Drivers::HardwareInfo::$module" }

require "TV/Drivers/HardwareInfo/$module.pm";
our @ISA = ( THardwareInfo );

1
