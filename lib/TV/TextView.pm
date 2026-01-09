package TV::TextView;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TV::TextView::TextDevice;
use TV::TextView::Terminal;

sub import {
  my $target = caller;
  TV::TextView::TextDevice->import::into( $target );
  TV::TextView::Terminal->import::into( $target );
}

sub unimport {
  my $caller = caller;
  TV::TextView::TextDevice->unimport::out_of( $caller );
  TV::TextView::Terminal->unimport::out_of( $caller );
}

1
