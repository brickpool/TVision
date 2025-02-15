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

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';

use TV::Drivers::HardwareInfo;

sub TSystemError() { __PACKAGE__ }

# Global variables
our $ctrlBreakHit  = !!0;
our $saveCtrlBreak = !!0;

INIT {
  TSystemError->resume();
}

END {
  TSystemError->suspend();
}

sub resume {    # void ($class)
  assert ( $_[0] and !ref $_[0] );
  THardwareInfo->setCtrlBrkHandler( !!1 ) unless STRICT;
  return;
}

sub suspend {    # void ($class)
  assert ( $_[0] and !ref $_[0] );
  THardwareInfo->setCtrlBrkHandler( !!0 ) unless STRICT;
  return;
}

1
