package TV::Drivers::HWMouse;
# ABSTRACT: defines the class THWMouse

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  THWMouse
);

use Devel::StrictMode;
use PerlX::Assert::PP;
use Scalar::Util qw( looks_like_number );

use TV::Drivers::HardwareInfo;

sub THWMouse() { __PACKAGE__ }

# predeclare global variable names
our $buttonCount      = 0;
our $handlerInstalled = !!0;
our $noMouse          = !!0;

INIT {
  THWMouse->resume();
}

END {
  THWMouse->suspend();
}

sub show {    # void ($class)
  assert ( $_[0] and !ref $_[0] );
  THardwareInfo->cursorOn();
  return;
}

sub hide {    # void ($class)
  assert ( $_[0] and !ref $_[0] );
  THardwareInfo->cursorOff();
  return;
}

sub setRange {    # void ($class, $rx, $ry)
  my ( $class, $rx, $ry ) = @_;
  assert ( $class and !ref $class );
  assert ( looks_like_number $rx );
  assert ( looks_like_number $ry );
  warn 'Unimplemented' if STRICT;
  return;
}

sub getEvent {    # void ($class, \%me)
  my ( $class, $me ) = @_;
  assert ( $class and !ref $class );
  assert ( ref $me );
  $me->{buttons}  = 0;
  $me->{where}{x} = 0;
  $me->{where}{y} = 0;
  $me->{eventFlags} = 0;
  return;
}

sub present {    # $bool ($class)
  assert ( $_[0] and !ref $_[0] );
  return $buttonCount != 0;
}

sub suspend {    # void ($class)
  my $class = shift;
  assert ( $class and !ref $class );
  $class->hide();
  $buttonCount = !!0;
  return;
}

sub resume {    # void ($class)
  my $class = shift;
  assert ( $class and !ref $class );
  $buttonCount = THardwareInfo->getButtonCount();
  $class->show();
  return;
}

sub inhibit {    # void ($class)
  assert ( $_[0] and !ref $_[0] );
  $noMouse = !!1;
  return;
}

1

__END__

=pod

=head1 NAME

TV::Drivers::HWMouse - defines the class THWMouse

=head1 DESCRIPTION

This Perl module contains the I<THWMouse> class. 

=head1 METHODS

The methods I<show>, I<hide>, I<setRange>, I<getEvent>, I<present>, 
I<suspend>, I<resume> and I<inhibit> are hardware-related methods. 

B<Note>: The methods I<show>, I<hide> and I<resume> requires I<THardwareInfo>.

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
