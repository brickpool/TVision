#!perl

use strict;
use warnings;

use Test::More qw( no_plan );

BEGIN {
  use_ok 'TV::Objects::Rect';
  use_ok 'TV::Dialogs::Const', qw( bfDefault ); 
  use_ok 'TV::Dialogs::Util', qw( hotKey );
  use_ok 'TV::Dialogs::History::HistList';
  use_ok 'TV::Dialogs::Dialog';
  use_ok 'TV::Dialogs::Button';
  use_ok 'TV::Dialogs::StaticText';
  use_ok 'TV::Dialogs::ParamText';
  use_ok 'TV::Dialogs::Label';
  use_ok 'TV::Dialogs::InputLine';
  use_ok 'TV::Dialogs::StrItem';
  use_ok 'TV::Dialogs::Cluster';
  use_ok 'TV::Dialogs::RadioButtons';
  use_ok 'TV::Dialogs::CheckBoxes';
}

isa_ok( TDialog->new( bounds => TRect->new(), title => 'title' ), TDialog );
isa_ok( TButton->new( bounds => TRect->new(), title => 'title', command => 0,
  flags => bfDefault ), TButton );
isa_ok( TStaticText->new( bounds => TRect->new(), text => 'text' ),
  TStaticText );
isa_ok( TParamText->new( bounds => TRect->new() ), TParamText );
isa_ok( TLabel->new( bounds => TRect->new(), text => 'text', link => undef ),
  TLabel );
isa_ok( TInputLine->new( bounds => TRect->new(), maxLen => 10, 
  validator => undef ), TInputLine );
isa_ok( TSItem->new( value => 'value',  next => undef ), TSItem );
isa_ok( TCluster->new( bounds => TRect->new(), strings => undef ), TCluster );
isa_ok( TRadioButtons->new( bounds => TRect->new(), strings => undef ), 
  TRadioButtons );
isa_ok( TCheckBoxes->new( bounds => TRect->new(), strings => undef ), 
  TCheckBoxes );
