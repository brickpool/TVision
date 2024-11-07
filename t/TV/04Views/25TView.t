=pod

=head1 DECRIPTION

The following test cases of class I<TView> cover the methods I<commandEnabled>, 
I<disableCommands>, I<enableCommands>, I<disableCommand>, I<enableCommand>, 
I<getCommands>, I<setCommands>, I<setCmdState>, I<endModal> and I<execute>.

=cut

use strict;
use warnings;

use Test::More tests => 15;
use Test::Exception;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Views::Const', qw( :cmXXXX );
  use_ok 'TV::Views::CommandSet';
  use_ok 'TV::Views::View';
}

my $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 10 );
isa_ok( $bounds, TRect );

# Test the commandEnabled method
subtest 'commandEnabled method' => sub {
  my $view = TView->new( bounds => $bounds );
  ok(
    $view->commandEnabled( CM_CANCEL ), 
    'commandEnabled method returns true'
  );
};

# Test the disableCommands method
subtest 'disableCommands method' => sub {
  my $view     = TView->new( bounds => $bounds );
  my $commands = TCommandSet->new();
  lives_ok { $view->disableCommands( $commands ) }
    'disableCommands method executed without errors';
};

# Test the enableCommands method
subtest 'enableCommands method' => sub {
  my $view     = TView->new( bounds => $bounds );
  my $commands = TCommandSet->new();
  lives_ok { $view->enableCommands( $commands ) }
    'enableCommands method executed without errors';
};

# Test the disableCommand method
subtest 'disableCommand method' => sub {
  my $view = TView->new( bounds => $bounds );
  lives_ok { $view->disableCommand( CM_CANCEL ) }
    'disableCommand method executed without errors';
  ok(
    !$view->commandEnabled( CM_CANCEL ),
    'commandEnabled method returns false'
  );
};

# Test the enableCommand method
subtest 'enableCommand method' => sub {
  my $view = TView->new( bounds => $bounds );
  ok(
    !$view->commandEnabled( CM_ZOOM ),
    'commandEnabled method returns false'
  );
  lives_ok { $view->enableCommand( CM_ZOOM ) }
    'enableCommand method executed without errors';
  ok(
    $view->commandEnabled( CM_ZOOM ),
    'commandEnabled method returns true'
  );
};

# Test the getCommands method
subtest 'getCommands method' => sub {
  my $view     = TView->new( bounds => $bounds );
  my $commands = TCommandSet->new();
  lives_ok { $view->getCommands( $commands ) }
    'getCommands method executed without errors';
};

# Test the setCommands method
subtest 'setCommands method' => sub {
  my $view     = TView->new( bounds => $bounds );
  my $commands = TCommandSet->new();
  lives_ok { $view->setCommands( $commands ) }
    'setCommands method executed without errors';
};

# Test the setCmdState method
subtest 'setCmdState method' => sub {
  my $view     = TView->new( bounds => $bounds );
  my $commands = TCommandSet->new();
  lives_ok { $view->setCmdState( $commands, !!1 ) }
    'setCmdState method executed without errors';
};

# Test the endModal method
subtest 'endModal method' => sub {
  my $view = TView->new( bounds => $bounds );
  lives_ok { $view->endModal( 256 ) }
    'endModal method executed without errors';
};

# Test the execute method
subtest 'execute method' => sub {
  my $view = TView->new( bounds => $bounds );
  is( $view->execute(), CM_CANCEL, 'execute method returns CM_CANCEL' );
};

done_testing;
