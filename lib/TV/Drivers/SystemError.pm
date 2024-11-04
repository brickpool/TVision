=pod

=head1 NAME

TV::Drivers::SystemError - defines the class TSystemError

=head1 DESCRIPTION

The class I<TSystemError> was ported to this Perl module. 

=head2 Methods 
 
The class methods I<resume> and I<suspend> have been ported. 

B<Note>: These methods requires I<THardwareInfo>.

=head2 Variables
 
The global variables I<$ctrlBreakHit> and I<$saveCtrlBreak> are addressed via 
the namespace of I<TSystemError>.

=cut

package TV::Drivers::SystemError;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TSystemError
);

use Data::Alias;

use TV::Drivers::HardwareInfo;

sub TSystemError() { __PACKAGE__ }

# Global variables
our $ctrlBreakHit  = !!0;
our $saveCtrlBreak = !!0;
{
  no warnings 'once';
  alias TSystemError->{ctrlBreakHit}  = $ctrlBreakHit;
  alias TSystemError->{saveCtrlBreak} = $saveCtrlBreak;
}

INIT: {
  TSystemError->resume();
}

END {
  TSystemError->suspend();
}

sub resume {    # void ($class)
  my ( $class ) = @_;
  THardwareInfo->setCtrlBrkHandler( !!1 );
  return;
}

sub suspend {    # void ($class)
  my ( $class ) = @_;
  THardwareInfo->setCtrlBrkHandler( !!0 );
  return;
}

1
