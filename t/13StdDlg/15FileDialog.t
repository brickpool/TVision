use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Drivers::Event';
  use_ok 'TV::Drivers::Const', qw( evCommand );
  use_ok 'TV::Views::Group';
  use_ok 'TV::StdDlg::Const', qw( cmFileOpen );
  use_ok 'TV::StdDlg::FileDialog';
  require_ok 'TV::toolkit';
}

BEGIN {
  package MyOwner;
  use TV::Views::Group;
  use TV::toolkit;
  extends 'TV::Views::Group';

  has wildCard  => ( is => 'rw' );
  has directory => ( is => 'rw' );

  $INC{"MyOwner.pm"} = 1;
}

use_ok 'MyOwner';

my $dlg;
my $owner;

subtest 'Object creation' => sub {
  my $bounds = TRect->new( ax => 0, ay => 0, bx => 80, by => 20 );

  lives_ok {
    $dlg = TFileDialog->new(
      wildCard  => '*.pl',
      title     => 'Test',
      inputName => '',
      options   => 0,
      histId    => 0,
    );
  } 'TFileDialog object created';
  isa_ok( $dlg, TFileDialog() );

  $owner = MyOwner->new( bounds => $bounds );
  $owner->wildCard( '*.pl' );
  $owner->directory( 'C:\\' );

  $dlg->owner( $owner );
}; #/ 'Object creation' => sub

subtest 'handleEvent() cmFileOpen survives' => sub {
  my $event = TEvent->new(
    what    => evCommand,
    command => cmFileOpen,
  );
  lives_ok { $dlg->handleEvent( $event )  } 'handleEvent() lives';
};

subtest 'getFileName() survives' => sub {
  my $name = '';
  lives_ok { $dlg->getFileName( $name ) } 'getFileName() does not die';
};

subtest 'valid() survives' => sub {
  lives_ok { $dlg->valid( 0 ) } 'valid() does not die';
};

subtest 'setData()/getData() survive' => sub {
  my @rec = ( 'test.txt' );

  lives_ok {
    $dlg->setData( \@rec );
    $dlg->getData( \@rec );
  } 'setData()/getData() do not die';
  like(
    ( $rec[0] || '' ), 
    qr/TEST\.TXT/, 
    'getData() returns the expected data'
  );
};

subtest 'shutDown() survives' => sub {
  lives_ok { $dlg->shutDown() } 'shutDown() does not die';
};

done_testing;
