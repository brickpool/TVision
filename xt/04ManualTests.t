use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  unless ( $^O eq 'MSWin32' ) {
    plan skip_all => 'This is not MSWin32';
  }
  else {
    plan tests => 4;
  }
}

package ConsoleManualTests {
  use strict;
  use warnings;

  use Devel::Assert 'on';
  use Test::More;

  BEGIN {
    use_ok 'TV::Objects::Rect';
    use_ok 'TV::App::Program';
  }

  use Exporter qw( import );
  our @EXPORT = qw(
    ManualTestsEnabled
    ProgramRun
  );

  use constant ManualTestsEnabled => exists($ENV{MANUAL_TESTS})
                                  && !$ENV{AUTOMATED_TESTING}
                                  && !$ENV{NONINTERACTIVE_TESTING};

  sub ProgramRun {    # void ()
    my $bounds = TRect->new( ax => 0, ay => 0, bx => 80, by => 25 );
    assert ( $bounds->isa( TRect ) );
    my $program = TProgram->new( bounds => $bounds );
    assert ( $program->isa( TProgram ) );
    $program->run();
  }

  $INC{__PACKAGE__ .'.pm'} = 1;
}

use_ok 'ConsoleManualTests';

SKIP: {
  skip 'Manual test not enabled', 1 unless ManualTestsEnabled();

  lives_ok { ProgramRun() } 'ProgramRun()';
};

done_testing;

__END__

=pod

=head1 System->Console manual tests

For verifying console functionality that cannot be run as fully automated. To 
run the suite, follow these steps:

=over

=item 1. Install the nesessary test libraries.

=item 2. Using a terminal, navigate to the current folder.

=item 3. Enable manual testing by defining the C<MANUAL_TESTS> environment 
variable (e.g. on cmd C<set MANUAL_TESTS=1>).

=item 4. Deactivate all standard environment variables for automated tests such 
as C<AUTOMATED_TESTING> or C<NONINTERACTIVE_TESTING> (e.g. with cmd 
C<set AUTOMATED_TESTING=>).

=item 5. Run C<prove> and follow the instructions in the command prompt.

=head2 Instructions for Windows testers

Test on Windows prints to console output, so in order to properly execute the 
manual tests, C<prove> must be invoked with argument C<-q> or C<-Q>. To do this 
run

  prove -l -q xt\*tests.t

=cut
