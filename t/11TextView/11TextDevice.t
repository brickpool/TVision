=pod

=head1 DESCRIPTION

The following test cases of class I<TTextDevice> cover the constructors I<new> 
and I<from> and the method I<overflow>. A custom subclass is used to implement 
I<do_sputn> for testing.

=cut

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::TextView::TextDevice';
  use_ok 'TV::Views::ScrollBar';
  use_ok 'TV::toolkit';
}

# Create a subclass for testing that implements do_sputn
{
  package MyTextDevice;
  use TV::toolkit;

  has data => ( id => 'bare', default => sub { '' } );

  extends 'TV::TextView::TextDevice';

  our $last_call = '';

  sub BUILD {
    my ( $self ) = @_;
    open( $self->{io}, '+>', \$self->{data} );
    return;
  }

  # Helper function to access last_call
  sub last_call { $last_call }

  sub do_sputn {
    my ( $self, $s, $count ) = @_;
    $last_call = "$s:$count";
    return $count;    # simulate success
  }
}

# ScrollBars
my $hBar = TScrollBar->new(
  bounds => TRect->new( ax => 0, ay => 0, bx => 10, by => 1 ) );
my $vBar = TScrollBar->new(
  bounds => TRect->new( ax => 0, ay => 0, bx => 1, by => 10 ) );

# Test object creation
my $device;
subtest 'Object creation' => sub {
  my $bounds = TRect->new( ax => 0, ay => 0, bx => 20, by => 10 );
  lives_ok { $device = MyTextDevice->from( $bounds, $hBar, $vBar ) }
    'TTextDevice object created';
  isa_ok( $device, TTextDevice );
};

# Test overflow with a character
subtest 'overflow' => sub {
  can_ok( $device, 'overflow' );
  my $result = $device->overflow(ord('A'));
  is($result, 1, 'overflow returns 1');
  is(MyTextDevice::last_call(), 'A:1', 'do_sputn was called with A and 1');
};

# Test tied text device methods
subtest 'tied text device' => sub {
  my $buf = '';
  tie *TXT, MyTextDevice=>(
    bounds      => new_TRect( 0, 0, 20, 10 ),
    aVScrollBar => $hBar,
    aHScrollBar => $vBar,
  );
  isa_ok( tied(*TXT), TTextDevice );
	lives_ok { print(TXT "print\n")  or die } 'print TXT';
	lives_ok { printf(TXT 'printf')  or die } 'print TXT';
	lives_ok { read(TXT, $buf, 1)    // die } 'read TXT, ...';
	lives_ok { seek(TXT, 0, 0)       or die } 'seek TXT, ...';
	lives_ok { getc TXT              or die } 'getc TXT';
	lives_ok { sysread(TXT, $buf, 1) // die } 'sysread TXT, ...';
	lives_ok { tell TXT              or die } 'tell TXT';
	lives_ok { eof TXT              and die } 'eof TXT';
	lives_ok { my $line = <TXT>      or die } '$_ = <TXT>';
	lives_ok { my @lines = <TXT>     or die } '@_ = <TXT>';
	dies_ok  { binmode( TXT )        // die } 'binmode TXT';
	lives_ok { close TXT             or die } 'close TXT';
	dies_ok  { syswrite(TXT, $buf)   // die } 'syswrite TXT, ...';
  is( length($buf), 1, 'buffer is not empty' );
}; #/ 'I/O handle' => sub

done_testing();
