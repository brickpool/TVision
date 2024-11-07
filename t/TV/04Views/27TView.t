=pod

=head1 DECRIPTION

The following test cases of class I<TView> cover the methods I<nextView>, 
I<prevView>, I<prev>, I<next>, I<makeFirst>, I<putInFrontOf>, I<TopView>, 
I<owner> and I<shutDown>. 

=cut

use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Views::View';
}

my $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 10 );
isa_ok( $bounds, TRect );

# Test the nextView method
subtest 'nextView method' => sub {
  my $view = TView->new( bounds => $bounds );
  ok( !$view->nextView(), 'nextView method returns undef' );
};

# Test the prevView method
subtest 'prevView method' => sub {
  my $view = TView->new( bounds => $bounds );
  ok( !$view->prevView(), 'prevView method returns undef' );
};

# Test the prev method
subtest 'prev method' => sub {
  my $view = TView->new( bounds => $bounds );
  ok( !$view->prev(), 'prev method returns undef' );
};

# Test the next method
subtest 'next method' => sub {
  my $view = TView->new( bounds => $bounds );
  ok( !$view->next(), 'next method returns undef' );
};

# Test the putInFrontOf method
subtest 'putInFrontOf method' => sub {
  my $view   = TView->new( bounds => $bounds );
  my $target = TView->new( bounds => $bounds );
  lives_ok { $view->putInFrontOf( $target ) }
    'putInFrontOf method executed without errors';
};

# Test the makeFirst method
subtest 'makeFirst method' => sub {
  my $view = TView->new( bounds => $bounds );
  lives_ok { $view->makeFirst() }
    'makeFirst method executed without errors';
};

# Test the TopView method
subtest 'TopView method' => sub {
  my $view = TView->new( bounds => $bounds );
  ok( !$view->TopView(), 'TopView method returns undef' );
};

done_testing;
