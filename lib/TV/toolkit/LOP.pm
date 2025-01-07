package TV::toolkit::LOP;

use strict;
use warnings;

use Module::Loaded;    # also loads 'base'
require base;          # .. but that could change in the future

# Code snippet taken from File::Spec
my %module; BEGIN { %module = (
  fields              => 'Class::Fields',
  # 'Class::LOP'        => 'Class::LOP',
  # 'Class::Tiny'       => 'Class::Tiny',
  # Moo                 => 'Moo',
  # Moose               => 'Moose',
  'UNIVERSAL::Object' => 'UNIVERSAL::Object'
)}

our $name; BEGIN {
  *name = \$TV::toolkit::name;
  foreach my $toolkit ( reverse sort keys %module ) {
    if ( Module::Loaded::is_loaded $toolkit ) {
      $name = $toolkit;
      last;
    }
  }
}

my $module = $module{$name} || 'Class::Fields';

require ''. base::_module_to_filename( 
  $name eq 'Class::LOP' 
    ? 'Class::LOP'
    : "TV::toolkit::LOP::$module" 
);

our @ISA = ( "${module}::LOP" );

1
