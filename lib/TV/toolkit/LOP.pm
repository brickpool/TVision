package TV::toolkit::LOP;

use strict;
use warnings;

use Module::Loaded;    # also loads 'base'
require base;          # .. but that could change in the future

our $name; 
BEGIN {
  $name = 'UNIVERSAL::Object';
  foreach my $toolkit ( qw( fields Class::LOP Class::Tiny Moo Moose) ) {
    if ( Module::Loaded::is_loaded $toolkit ) {
      $name = $toolkit;
      last;
    }
  }
}

# Code snippet taken from File::Spec
my %module = (
  fields        => 'Class::Fields',
  'Class::LOP'  => 'Class',
  'Class::Tiny' => 'Class::Tiny',
  Moo           => 'Moo',
  Moose         => 'Moose',
);

my $module = $module{$name} || 'UNIVERSAL::Object';

require ''. base::_module_to_filename( 
  $name eq 'Class::LOP' 
    ? 'Class::LOP' 
    : "TV::toolkit::LOP::$module" 
);

our @ISA = ( "${module}::LOP" );

1
