package TV::Drivers::SystemError;
# ABSTRACT: defines the class TSystemError

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TSystemError
);

use Devel::StrictMode;
use PerlX::Assert::PP;

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

__END__

=pod

=head1 NAME

TV::Drivers::SystemError - defines the class TSystemError

=head1 DESCRIPTION

The class I<TSystemError> was ported to this Perl module. 

=head1 VARIABLES
 
The global variables I<$ctrlBreakHit> and I<$saveCtrlBreak> are addressed via 
the namespace of I<TSystemError>.

=head1 METHODS
 
The class methods I<resume> and I<suspend> have been ported. 

B<Note>: These methods requires I<THardwareInfo>.

=head1 AUTHORS

=over

=item Turbo Vision Development Team

=item J. Schneider <brickpool@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution). This documentation is provided under the same terms 
as the Turbo Vision library itself.

=cut
