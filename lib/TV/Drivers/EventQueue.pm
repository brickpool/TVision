package TV::Drivers::EventQueue;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw( TEventQueue );

# Code snippet taken from File::Spec
my %module = (
  MSWin32 => 'Win32',
);

my $module = $module{$^O} || 'Unix';

sub TEventQueue() { "TV::Drivers::EventQueue::$module" }

require "TV/Drivers/EventQueue/$module.pm";
our @ISA = ( TEventQueue );

1
