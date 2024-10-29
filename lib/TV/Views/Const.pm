=pod

=head1 DECRIPTION

In this Perl module, the constants for I<Views> are defined according to the 
naming conventions in Perl, using capital letters and underscores between the 
word boundaries. The constants are defined with I<use constant> to specify their
values.

=cut

package TV::Views::Const;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(
  MAX_VIEW_WIDTH
);

our %EXPORT_TAGS = (
  cmXXXX => [qw(
    CM_VALID 
    CM_QUIT 
    CM_ERROR 
    CM_MENU 
    CM_CLOSE 
    CM_ZOOM 
    CM_RESIZE 
    CM_NEXT 
    CM_PREV
    CM_HELP 
    CM_OK 
    CM_CANCEL 
    CM_YES 
    CM_NO 
    CM_DEFAULT 
    CM_NEW 
    CM_OPEN 
    CM_SAVE
    CM_SAVE_AS 
    CM_SAVE_ALL 
    CM_CH_DIR 
    CM_DOS_SHELL 
    CM_CLOSE_ALL
    
    CM_CUT 
    CM_COPY 
    CM_PASTE 
    CM_UNDO
    CM_CLEAR 
    CM_TILE 
    CM_CASCADE 
    CM_RECEIVED_FOCUS 
    CM_RELEASED_FOCUS
    CM_COMMAND_SET_CHANGED 
    CM_SCROLL_BAR_CHANGED 
    CM_SCROLL_BAR_CLICKED
    CM_SELECT_WINDOW_NUM 
    CM_LIST_ITEM_SELECTED
  )],

  sfXXXX => [qw(
    SF_VISIBLE
    SF_CURSOR_VIS 
    SF_CURSOR_INS 
    SF_SHADOW 
    SF_ACTIVE 
    SF_SELECTED 
    SF_FOCUSED
    SF_DRAGGING 
    SF_DISABLED 
    SF_MODAL 
    SF_DEFAULT 
    SF_EXPOSED
  )],

  ofXXXX => [qw(
    OF_SELECTABLE
    OF_TOP_SELECT 
    OF_FIRST_CLICK 
    OF_FRAMED 
    OF_PRE_PROCESS 
    OF_POST_PROCESS
    OF_BUFFERED 
    OF_TILEABLE 
    OF_CENTER_X 
    OF_CENTER_Y 
    OF_CENTERED 
    OF_VALIDATE
  )],

  gfXXXX => [qw(
    GF_GROW_LO_X 
    GF_GROW_LO_Y 
    GF_GROW_HI_X 
    GF_GROW_HI_Y 
    GF_GROW_ALL 
    GF_GROW_REL
    GF_FIXED
  )],

  dmXXXX => [qw(
    DM_DRAG_MOVE 
    DM_DRAG_GROW 
    DM_LIMIT_LO_X 
    DM_LIMIT_LO_Y 
    DM_LIMIT_HI_X
    DM_LIMIT_HI_Y 
    DM_LIMIT_ALL
  )],

  hcXXXX => [qw(
    HC_NO_CONTEXT 
    HC_DRAGGING
  )],

  sbXXXX => [qw(
    SB_LEFT_ARROW
    SB_RIGHT_ARROW 
    SB_PAGE_LEFT 
    SB_PAGE_RIGHT 
    SB_UP_ARROW 
    SB_DOWN_ARROW
    SB_PAGE_UP 
    SB_PAGE_DOWN 
    SB_INDICATOR 
    SB_HORIZONTAL 
    SB_VERTICAL
    SB_HANDLE_KEYBOARD
  )],

  wfXXXX => [qw(
    WF_MOVE 
    WF_GROW 
    WF_CLOSE 
    WF_ZOOM 
  )],

  noXXXX => [qw(
    NO_MENU_BAR 
    NO_DESK_TOP
    NO_STATUS_LINE 
    NO_BACKGROUND 
    NO_FRAME 
    NO_VIEWER 
    NO_HISTORY
  )],

  wnXXXX => [qw(
    WN_NO_NUMBER
  )],

  wpXXXX => [qw(
    WP_BLUE_WINDOW 
    WP_CYAN_WINDOW 
    WP_GRAY_WINDOW
  )],

  evXXXX => [qw(
    POSITIONAL_EVENTS
    FOCUSED_EVENTS
  )],
);

use TV::Drivers::Const qw(
  EV_MOUSE
  EV_KEYBOARD
  EV_COMMAND
);

use constant {
  MAX_VIEW_WIDTH      => 132,
};

use constant {
  # Standard command codes
  CM_VALID         => 0,
  CM_QUIT          => 1,
  CM_ERROR         => 2,
  CM_MENU          => 3,
  CM_CLOSE         => 4,
  CM_ZOOM          => 5,
  CM_RESIZE        => 6,
  CM_NEXT          => 7,
  CM_PREV          => 8,
  CM_HELP          => 9,
};

use constant {
  # TDialog standard commands
  CM_OK            => 10,
  CM_CANCEL        => 11,
  CM_YES           => 12,
  CM_NO            => 13,
  CM_DEFAULT       => 14,
};

use constant {
  # Standard application commands
  CM_NEW           => 30,
  CM_OPEN          => 31,
  CM_SAVE          => 32,
  CM_SAVE_AS       => 33,
  CM_SAVE_ALL      => 34,
  CM_CH_DIR        => 35,
  CM_DOS_SHELL     => 36,
  CM_CLOSE_ALL     => 37,
};

use constant {
  # TView State masks
  SF_VISIBLE       => 0x001,
  SF_CURSOR_VIS    => 0x002,
  SF_CURSOR_INS    => 0x004,
  SF_SHADOW        => 0x008,
  SF_ACTIVE        => 0x010,
  SF_SELECTED      => 0x020,
  SF_FOCUSED       => 0x040,
  SF_DRAGGING      => 0x080,
  SF_DISABLED      => 0x100,
  SF_MODAL         => 0x200,
  SF_DEFAULT       => 0x400,
  SF_EXPOSED       => 0x800,
};

use constant {
  # TView Option masks
  OF_SELECTABLE    => 0x001,
  OF_TOP_SELECT    => 0x002,
  OF_FIRST_CLICK   => 0x004,
  OF_FRAMED        => 0x008,
  OF_PRE_PROCESS   => 0x010,
  OF_POST_PROCESS  => 0x020,
  OF_BUFFERED      => 0x040,
  OF_TILEABLE      => 0x080,
  OF_CENTER_X      => 0x100,
  OF_CENTER_Y      => 0x200,
  OF_CENTERED      => 0x300,
  OF_VALIDATE      => 0x400,
};

use constant {
  # TView GrowMode masks
  GF_GROW_LO_X     => 0x01,
  GF_GROW_LO_Y     => 0x02,
  GF_GROW_HI_X     => 0x04,
  GF_GROW_HI_Y     => 0x08,
  GF_GROW_ALL      => 0x0f,
  GF_GROW_REL      => 0x10,
  GF_FIXED         => 0x20,
};

use constant {
  # TView DragMode masks
  DM_DRAG_MOVE     => 0x01,
  DM_DRAG_GROW     => 0x02,
  DM_LIMIT_LO_X    => 0x10,
  DM_LIMIT_LO_Y    => 0x20,
  DM_LIMIT_HI_X    => 0x40,
  DM_LIMIT_HI_Y    => 0x80,
  DM_LIMIT_ALL     => 0xF0,
};

use constant {
  # TView Help context codes
  HC_NO_CONTEXT    => 0,
  HC_DRAGGING      => 1,
};

use constant {
  # TScrollBar part codes
  SB_LEFT_ARROW    => 0,
  SB_RIGHT_ARROW   => 1,
  SB_PAGE_LEFT     => 2,
  SB_PAGE_RIGHT    => 3,
  SB_UP_ARROW      => 4,
  SB_DOWN_ARROW    => 5,
  SB_PAGE_UP       => 6,
  SB_PAGE_DOWN     => 7,
  SB_INDICATOR     => 8,
};

use constant {
  # TScrollBar options for TWindow->standardScrollBar
  SB_HORIZONTAL       => 0x000,
  SB_VERTICAL         => 0x001,
  SB_HANDLE_KEYBOARD  => 0x002,
};

use constant {
  # TWindow Flags masks
  WF_MOVE          => 0x01,
  WF_GROW          => 0x02,
  WF_CLOSE         => 0x04,
  WF_ZOOM          => 0x08,
};

use constant {
  # TView inhibit flags
  NO_MENU_BAR      => 0x0001,
  NO_DESK_TOP      => 0x0002,
  NO_STATUS_LINE   => 0x0004,
  NO_BACKGROUND    => 0x0008,
  NO_FRAME         => 0x0010,
  NO_VIEWER        => 0x0020,
  NO_HISTORY       => 0x0040,
};

use constant {
  # TWindow number constants
  WN_NO_NUMBER     => 0,
};

use constant {
  # TWindow palette entries
  WP_BLUE_WINDOW   => 0,
  WP_CYAN_WINDOW   => 1,
  WP_GRAY_WINDOW   => 2,
};

use constant {
  # Application command codes
  CM_CUT           => 20,
  CM_COPY          => 21,
  CM_PASTE         => 22,
  CM_UNDO          => 23,
  CM_CLEAR         => 24,
  CM_TILE          => 25,
  CM_CASCADE       => 26,
};

use constant {
  # Standard messages
  CM_RECEIVED_FOCUS       => 50,
  CM_RELEASED_FOCUS       => 51,
  CM_COMMAND_SET_CHANGED  => 52,
};

use constant {
  # TScrollBar messages
  CM_SCROLL_BAR_CHANGED  => 53,
  CM_SCROLL_BAR_CLICKED  => 54,
};

use constant {
  # TWindow select messages
  CM_SELECT_WINDOW_NUM   => 55,
};

use constant {
  # TListViewer messages
  CM_LIST_ITEM_SELECTED  => 56,
};

use constant {
  # Event masks
  POSITIONAL_EVENTS    => EV_MOUSE,
  FOCUSED_EVENTS       => EV_KEYBOARD | EV_COMMAND,
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
