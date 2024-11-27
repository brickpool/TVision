#!perl
use strict;
use warnings;

use base ();
use lib qw( ./lib );
use mro  ();
use Getopt::Long;
use Module::Overview;
use Text::SimpleTable;

my $target;
my $help;

# Get the command line options
GetOptions(
  'class=s' => \$target,
  'help|?'  => \$help,
) or die "Error in command line arguments\n";

# Display usage information if help is requested or class parameter is not used.
if ( $help || !defined $target ) {
	print_usage();
	exit;
}

# Check if the class parameter is provided
eval "require $target" 
  or die "Can't load class [$target]\n";

my $mo = Module::Overview->new({
  module_name => $target,
});
print $mo->text_simpletable;

my $table = Text::SimpleTable->new(16, 60);
my @fields = ();
for my $class ( reverse @{ mro::get_linear_isa( $target ) } ) {
  my %FIELDS = %{ base::get_fields( $class ) };
  for my $name ( sort { $FIELDS{$a} <=> $FIELDS{$b} } keys %FIELDS ) {
    my $no = $FIELDS{$name} || next;
    my $fattr = base::get_attr( $class )->[$no];
	  next if !$fattr || ( $fattr & base::INHERITED );
    push @fields, $target ne $class ? "$name [$class]" : $name;
  }
}
$table->row( 'fields', join "\n" => @fields );
print $table->draw;

# Function to display usage information
sub print_usage {
  print << "END_USAGE";
Usage: perl overview.pl [options]
Options:
    --class|c <string>   Input class to be processed
    --help|?             Display this help message
END_USAGE
}
