package TV::MsgBox::MsgBoxText;
# ABSTRACT: Message Box and Input Box functions for TVision

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(
  messageBox
  messageBoxRect
  inputBox
  inputBoxRect
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::App::Program qw(
  $application
  $deskTop
);
use TV::Dialogs::Const qw(
  bfDefault
  bfNormal
);
use TV::Dialogs::Button;
use TV::Dialogs::Dialog;
use TV::Dialogs::InputLine;
use TV::Dialogs::Label;
use TV::Dialogs::StaticText;
use TV::MsgBox::Const qw(
  :mfXXXX
);
use TV::Objects::Object;
use TV::Objects::Rect;
use TV::Views::Const qw(
  cmYes
  cmNo
  cmOK
  cmCancel
);

# declare global variables
our $yesText         = "~Y~es";
our $noText          = "~N~o";
our $okText          = "O~K~";
our $cancelText      = "Cancel";
our $warningText     = "Warning";
our $errorText       = "Error";
our $informationText = "Information";
our $confirmText     = "Confirm";

# Button caption texts
my @buttonName = (
  $yesText,
  $noText,
  $okText,
  $cancelText,
);

# Commands for each button
my @commands = (
  cmYes,
  cmNo,
  cmOK,
  cmCancel,
);

# Titles for different message box types
my @Titles = (
  $warningText,
  $errorText,
  $informationText,
  $confirmText,
);

sub messageBox {    # $command ($msg|$aOptions, $aOptions|$fmt, |@list)
  assert ( @_ >= 2 );
  my $r = TRect->new( ax => 0, ay => 0, bx => 40, by => 9 );
  $r->move(
    int( ( $deskTop->{size}{x} - $r->{b}{x} ) / 2 ),
    int( ( $deskTop->{size}{y} - $r->{b}{y} ) / 2 ),
  );
  return messageBoxRect( $r, @_ );
}

sub messageBoxRect {    # $command ($r, $msg|$aOptions, $aOptions|$fmt, |@list)
  my ( $r, $msg, $aOptions );
  assert ( @_ >= 3 );
  if ( @_ > 3 || looks_like_number $_[1] || !looks_like_number $_[2] ) {
    my ( $fmt, @list );
    ( $r, $aOptions, $fmt, @list ) = @_;
    assert ( defined $fmt and !ref $fmt );
    $msg = sprintf( $fmt, @list );
  } 
  else {
    ( $r, $msg, $aOptions ) = @_;
  }
  assert ( ref $r );
  assert ( defined $msg and !ref $msg );
  assert ( looks_like_number $aOptions );

  my $dialog;
  my ( $i, $x, $buttonCount );
  my @buttonList;
  my $ccode;

  $dialog = TDialog->new( bounds => $r, title  => $Titles[ $aOptions & 0x3 ] );

  $dialog->insert(
    TStaticText->new(
      bounds => TRect->new(
        ax => 3,
        ay => 2,
        bx => $dialog->{size}{x} - 2,
        by => $dialog->{size}{y} - 3,
      ),
      text => $msg,
    )
  );
  for ( $i = 0, $x = -2, $buttonCount = 0 ; $i < 4 ; $i++ ) {
    if ( $aOptions & ( 0x0100 << $i ) ) {
      $buttonList[$buttonCount] = TButton->new(
        bounds  => TRect->new( ax => 0, ay => 0, bx => 10, by => 2 ),
        title   => $buttonName[$i],
        command => $commands[$i],
        flags   => bfNormal,
      );
      $x += $buttonList[$buttonCount++]->{size}{x} + 2;
    } #/ if ( ( $aOptions & ( 0x0100...)))
  } #/ for ( $i = 0, $x = -2, ...)

  $x = int( ( $dialog->{size}{x} - $x ) / 2 );

  for ( $i = 0 ; $i < $buttonCount ; $i++ ) {
    $dialog->insert( $buttonList[$i] );
    $buttonList[$i]->moveTo( $x, $dialog->{size}{y} - 3 );
    $x += $buttonList[$i]->{size}{x} + 2;
  }

  $dialog->selectNext( !!0 );

  $ccode = $application->execView( $dialog );

  TObject->destroy( $dialog );

  return $ccode;
}; #/ sub messageBoxRect

sub inputBox {    # $command ($Title, $aLabel, $s, $limit)
  assert ( @_ == 4 );
  my $r = TRect->new( ax => 0, ay => 0, bx => 60, by => 8 );
  $r->move(
    int( ( $deskTop->{size}{x} - $r->{b}{x} ) / 2 ),
    int( ( $deskTop->{size}{y} - $r->{b}{y} ) / 2 ),
  );
  return inputBoxRect( $r, @_ );
}

sub inputBoxRect {    # $command ($bounds, $Title, $aLabel, $s, $limit)
  my ( $bounds, $Title, $aLabel, $s, $limit ) = @_;
  assert ( @_ == 5 );
  assert ( blessed $bounds );
  assert ( defined $Title and !ref $Title );
  assert ( defined $aLabel and !ref $aLabel );
  assert ( ref $s );
  assert ( looks_like_number $limit );

  my $dialog;
  my $control;
  my $r;
  my $c;

  $dialog = TDialog->new( bounds => $bounds, title => $Title );
  $r = TRect->new(
    ax => 4 + length( $aLabel ),  ay => 2,
    bx => $dialog->{size}{x} - 3, by => 3,
  );
  $control = TInputLine->new( bounds => $r, maxLen => $limit );
  $dialog->insert( $control );

  $r = TRect->new( ax => 2, ay => 2, bx => 3 + length( $aLabel ), by => 3 );
  $dialog->insert(
    TLabel->new( bounds => $r, text => $aLabel, link => $control )
  );

  $r = TRect->new(
    ax => $dialog->{size}{x} - 24, ay => $dialog->{size}{y} - 4,
    bx => $dialog->{size}{x} - 14, by => $dialog->{size}{y} - 2,
  );
  $dialog->insert(
    TButton->new(
      bounds  => $r,
      title   => $okText,
      command => cmOK,
      flags   => bfDefault,
    )
  );

  $r->{a}{x} += 12;
  $r->{b}{x} += 12;
  $dialog->insert(
    TButton->new(
      bounds  => $r,
      title   => $cancelText,
      command => cmCancel,
      flags   => bfNormal,
    )
  );

  $r->{a}{x} += 12;
  $r->{b}{x} += 12;
  $dialog->selectNext( !!0 );
  $dialog->setData( $s );
  $c = $application->execView( $dialog );
  if ( $c != cmCancel ) {
    $dialog->getData( $s );
  }
  TObject->destroy( $dialog );
  return $c;
} #/ sub inputBoxRect

1
