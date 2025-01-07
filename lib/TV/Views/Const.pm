=pod

=head1 DESCRIPTION

In this Perl module, the constants for I<Views> are defined according to the 
naming conventions in Perl, using capital letters and underscores between the 
word boundaries. The constants are defined with I<use constant> to specify their
values.

=cut

package TV::Views::Const;

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT_OK = qw(
  maxViewWidth
);

our %EXPORT_TAGS = (

  phaseType => [qw(
    phFocused
    phPreProcess
    phPostProcess
  )],

  selectMode => [qw(
    normalSelect
    enterSelect
    leaveSelect
  )],

  cmXXXX => [qw(
    cmValid 
    cmQuit 
    cmError 
    cmMenu 
    cmClose 
    cmZoom 
    cmResize 
    cmNext 
    cmPrev
    cmHelp 
    cmOk 
    cmCancel 
    cmYes 
    cmNo 
    cmDefault 
    cmNew 
    cmOpen 
    cmSave
    cmSaveAs 
    cmSaveAll 
    cmChDir 
    cmDosShell 
    cmCloseAll
    
    cmCut 
    cmCopy 
    cmPaste 
    cmUndo
    cmClear 
    cmTile 
    cmCascade 
    cmReceivedFocus 
    cmReleasedFocus
    cmCommandSetChanged 
    cmScrollBarChanged 
    cmScrollBarClicked
    cmSelectWindowNum 
    cmListItemSelected
  )],

  sfXXXX => [qw(
    sfVisible
    sfCursorVis 
    sfCursorIns 
    sfShadow 
    sfActive 
    sfSelected 
    sfFocused
    sfDragging 
    sfDisabled 
    sfModal 
    sfDefault 
    sfExposed
  )],

  ofXXXX => [qw(
    ofSelectable
    ofTopSelect 
    ofFirstClick 
    ofFramed 
    ofPreProcess 
    ofPostProcess
    ofBuffered 
    ofTileable 
    ofCenterX 
    ofCenterY 
    ofCentered 
    ofValidate
  )],

  gfXXXX => [qw(
    gfGrowLoX 
    gfGrowLoY 
    gfGrowHiX 
    gfGrowHiY 
    gfGrowAll 
    gfGrowRel
    gfFixed
  )],

  dmXXXX => [qw(
    dmDragMove 
    dmDragGrow 
    dmLimitLoX 
    dmLimitLoY 
    dmLimitHiX
    dmLimitHiY 
    dmLimitAll
  )],

  hcXXXX => [qw(
    hcNoContext 
    hcDragging
  )],

  sbXXXX => [qw(
    sbLeftArrow
    sbRightArrow 
    sbPageLeft 
    sbPageRight 
    sbUpArrow 
    sbDownArrow
    sbPageUp 
    sbPageDown 
    sbIndicator 
    sbHorizontal 
    sbVertical
    sbHandleKeyboard
  )],

  wfXXXX => [qw(
    wfMove 
    wfGrow 
    wfClose 
    wfZoom 
  )],

  noXXXX => [qw(
    noMenuBar 
    noDeskTop
    noStatusLine 
    noBackground 
    noFrame 
    noViewer 
    noHistory
  )],

  wnXXXX => [qw(
    wnNoNumber
  )],

  wpXXXX => [qw(
    wpBlueWindow 
    wpCyanWindow 
    wpGrayWindow
  )],

  evXXXX => [qw(
    positionalEvents
    focusedEvents
  )],

  cpXXXX => [qw(
    cpFrame
    cpScrollBar
    cpBlueWindow
    cpCyanWindow
    cpGrayWindow
  )],

);

use TV::Drivers::Const qw(
  evMouse
  evKeyboard
  evCommand
);

use constant {
  maxViewWidth    => 132,
};

# Constants for phaseType
use constant {
  phFocused       => 0,
  phPreProcess    => 1,
  phPostProcess   => 2,
};

# Constants for selectMode
use constant {
  normalSelect    => 0,
  enterSelect     => 1,
  leaveSelect     => 2,
};

use constant {
  # Standard command codes
  cmValid         => 0,
  cmQuit          => 1,
  cmError         => 2,
  cmMenu          => 3,
  cmClose         => 4,
  cmZoom          => 5,
  cmResize        => 6,
  cmNext          => 7,
  cmPrev          => 8,
  cmHelp          => 9,
};

use constant {
  # TDialog standard commands
  cmOk            => 10,
  cmCancel        => 11,
  cmYes           => 12,
  cmNo            => 13,
  cmDefault       => 14,
};

use constant {
  # Standard application commands
  cmNew           => 30,
  cmOpen          => 31,
  cmSave          => 32,
  cmSaveAs        => 33,
  cmSaveAll       => 34,
  cmChDir         => 35,
  cmDosShell      => 36,
  cmCloseAll      => 37,
};

use constant {
  # TView State masks
  sfVisible       => 0x001,
  sfCursorVis     => 0x002,
  sfCursorIns     => 0x004,
  sfShadow        => 0x008,
  sfActive        => 0x010,
  sfSelected      => 0x020,
  sfFocused       => 0x040,
  sfDragging      => 0x080,
  sfDisabled      => 0x100,
  sfModal         => 0x200,
  sfDefault       => 0x400,
  sfExposed       => 0x800,
};

use constant {
  # TView Option masks
  ofSelectable    => 0x001,
  ofTopSelect     => 0x002,
  ofFirstClick    => 0x004,
  ofFramed        => 0x008,
  ofPreProcess    => 0x010,
  ofPostProcess   => 0x020,
  ofBuffered      => 0x040,
  ofTileable      => 0x080,
  ofCenterX       => 0x100,
  ofCenterY       => 0x200,
  ofCentered      => 0x300,
  ofValidate      => 0x400,
};

use constant {
  # TView GrowMode masks
  gfGrowLoX       => 0x01,
  gfGrowLoY       => 0x02,
  gfGrowHiX       => 0x04,
  gfGrowHiY       => 0x08,
  gfGrowAll       => 0x0f,
  gfGrowRel       => 0x10,
  gfFixed         => 0x20,
};

use constant {
  # TView DragMode masks
  dmDragMove      => 0x01,
  dmDragGrow      => 0x02,
  dmLimitLoX      => 0x10,
  dmLimitLoY      => 0x20,
  dmLimitHiX      => 0x40,
  dmLimitHiY      => 0x80,
  dmLimitAll      => 0xF0,
};

use constant {
  # TView Help context codes
  hcNoContext     => 0,
  hcDragging      => 1,
};

use constant {
  # TScrollBar part codes
  sbLeftArrow     => 0,
  sbRightArrow    => 1,
  sbPageLeft      => 2,
  sbPageRight     => 3,
  sbUpArrow       => 4,
  sbDownArrow     => 5,
  sbPageUp        => 6,
  sbPageDown      => 7,
  sbIndicator     => 8,
};

use constant {
  # TScrollBar options for TWindow->standardScrollBar
  sbHorizontal      => 0x000,
  sbVertical        => 0x001,
  sbHandleKeyboard  => 0x002,
};

use constant {
  # TWindow Flags masks
  wfMove          => 0x01,
  wfGrow          => 0x02,
  wfClose         => 0x04,
  wfZoom          => 0x08,
};

use constant {
  # TView inhibit flags
  noMenuBar       => 0x0001,
  noDeskTop       => 0x0002,
  noStatusLine    => 0x0004,
  noBackground    => 0x0008,
  noFrame         => 0x0010,
  noViewer        => 0x0020,
  noHistory       => 0x0040,
};

use constant {
  # TWindow number constants
  wnNoNumber      => 0,
};

use constant {
  # TWindow palette entries
  wpBlueWindow    => 0,
  wpCyanWindow    => 1,
  wpGrayWindow    => 2,
};

use constant {
  # Application command codes
  cmCut           => 20,
  cmCopy          => 21,
  cmPaste         => 22,
  cmUndo          => 23,
  cmClear         => 24,
  cmTile          => 25,
  cmCascade       => 26,
};

use constant {
  # Standard messages
  cmReceivedFocus     => 50,
  cmReleasedFocus     => 51,
  cmCommandSetChanged => 52,
};

use constant {
  # TScrollBar messages
  cmScrollBarChanged  => 53,
  cmScrollBarClicked  => 54,
};

use constant {
  # TWindow select messages
  cmSelectWindowNum   => 55,
};

use constant {
  # TListViewer messages
  cmListItemSelected  => 56,
};

use constant {
  # Event masks
  positionalEvents    => evMouse,
  focusedEvents       => evKeyboard | evCommand,
};

use constant {
  # TFrame palette
  cpFrame => "\x01\x01\x02\x02\x03",
};

use constant {
  # TScrollBar palette
  cpScrollBar => "\x04\x05\x05",
};

use constant {
  # TWindow palettes
  cpBlueWindow => "\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F",
  cpCyanWindow => "\x10\x11\x12\x13\x14\x15\x16\x17",
  cpGrayWindow => "\x18\x19\x1A\x1B\x1C\x1D\x1E\x1F",
};

# add all the other %EXPORT_TAGS ":class" tags to the ":all" class and
# @EXPORT_OK, deleting duplicates
{
  my %seen;
  push
    @EXPORT_OK,
      grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}}
        foreach keys %EXPORT_TAGS;
  push
    @{$EXPORT_TAGS{all}},
      @EXPORT_OK;
}

1;
