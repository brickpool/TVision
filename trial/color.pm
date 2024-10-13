use 5.014;
use warnings;

package Color;
  
use constant CAppColor => 
#      ,-------------------- Background
#      !   ,----------------- Normal Text
#      !   !   ,-------------- Disabled Text
#      !   !   !   ,----------- Shortcut Text
#      !   !   !   !   ,-------- Normal selection
#      !   !   !   !   !   ,----- Disabled selection
#      !   !   !   !   !   !   ,-- Shortcut selection
    "\x71\x70\x78\x74\x20\x28\x24"                        # Menu and StatusLine

#      ,----------------------- Frame Passive
#      !   ,-------------------- Frame Active
#      !   !   ,----------------- Frame Icon
#      !   !   !   ,-------------- ScrollBar Page
#      !   !   !   !   ,----------- ScrollBar reserved
#      !   !   !   !   !   ,-------- Scroller Normal Text
#      !   !   !   !   !   !   ,----- Scroller Selected Text
#      !   !   !   !   !   !   !   ,-- Reserved
  . "\x17\x1F\x1A\x31\x31\x1E\x71\x1F"                    # Blue window
  . "\x37\x3F\x3A\x13\x13\x3E\x21\x3F"                    # Cyan window
  . "\x70\x7F\x7A\x13\x13\x70\x7F\x7E"                    # Gray window

#      ,-------------------------- Frame Passive
#      !   ,----------------------- Frame Active
#      !   !   ,-------------------- Frame Icon
#      !   !   !   ,----------------- ScrollBar Page
#      !   !   !   !   ,-------------- ScrollBar Controls
#      !   !   !   !   !   ,----------- StaticText
#      !   !   !   !   !   !   ,-------- Label Normal
#      !   !   !   !   !   !   !   ,----- Label Highlight
#      !   !   !   !   !   !   !   !   ,-- Label Shortcut
  . "\x70\x7F\x7A\x13\x13\x70\x70\x7F\x7E"                # Gray dialog

#      ,-------------------------- Button Normal
#      !   ,----------------------- Button Default
#      !   !   ,-------------------- Button Selected
#      !   !   !   ,----------------- Button Disabled
#      !   !   !   !   ,-------------- Button Shortcut
#      !   !   !   !   !   ,----------- Button Shadow
#      !   !   !   !   !   !   ,-------- Cluster Normal
#      !   !   !   !   !   !   !   ,----- Cluster Selected
#      !   !   !   !   !   !   !   !   ,-- Cluster Shortcut
  . "\x20\x2B\x2F\x78\x2E\x70\x30\x3F\x3E"                # Gray dialog

#      ,-------------------- InputLine Normal
#      !   ,----------------- InputLine Selected
#      !   !   ,-------------- InputLine Arrows
#      !   !   !   ,----------- History Arrow
#      !   !   !   !   ,-------- History Sides
#      !   !   !   !   !   ,----- HistoryWindow ScrollBar page
#      !   !   !   !   !   !   ,-- HistoryWindow ScrollBar controls
  . "\x1F\x2F\x1A\x20\x72\x31\x31"                        # Gray dialog
  
#      ,-------------------- ListViewer Normal
#      !   ,----------------- ListViewer Focused
#      !   !   ,-------------- ListViewer Selected
#      !   !   !   ,----------- ListViewer Divider
#      !   !   !   !   ,-------- InfoPane
#      !   !   !   !   !   ,----- Cluster disabled
#      !   !   !   !   !   !   ,-- Reserved
  . "\x30\x2F\x3E\x31\x13\x38\x00"                        # Gray dialog

  . "\x17\x1F\x1A\x71\x71\x1E\x17\x1F\x1E"                # Blue dialog
  . "\x20\x2B\x2F\x78\x2E\x10\x30\x3F\x3E"
  . "\x70\x2F\x7A\x20\x12\x31\x31"
  . "\x30\x2F\x3E\x31\x13\x38\x00"

  . "\x37\x3F\x3A\x13\x13\x3E\x30\x3F\x3E"                # Cyan dialog
  . "\x20\x2B\x2F\x78\x2E\x30\x70\x7F\x7E"
  . "\x1F\x2F\x1A\x20\x32\x31\x71"
  . "\x70\x2F\x7E\x71\x13\x38\x00";


#                                       ,-- Color
use constant CBackground  => pack('C*', 1);                                  # Background colour

#                                       ,------------ Text Normal
#                                       !  ,---------- Text Disabled
#                                       !  !  ,-------- Text Shortcut
#                                       !  !  !  ,------ Selected Normal
#                                       !  !  !  !  ,---- Selected Disabled
#                                       !  !  !  !  !  ,-- Selected Shortcut
use constant CMenuView    => pack('C*', 2, 3, 4, 5, 6, 7);                  # Menu colours
use constant CStatusLine  => pack('C*', 2, 3, 4, 5, 6, 7);                  # Statusline colours

#                                       ,---------------- Frame Passive
#                                       !  ,-------------- Frame Active
#                                       !  !  ,------------ Frame Icon
#                                       !  !  !  ,---------- ScrollBar Page
#                                       !  !  !  !  ,-------- ScrollBar Reserved
#                                       !  !  !  !  !  ,------ Scroller Normal Text
#                                       !  !  !  !  !  !  ,---- Scroller Selected Text
#                                       !  !  !  !  !  !  !  ,-- Reserved
use constant CBlueWindow => pack('C*',  8, 9,10,11,12,13,14,15);            # Blue window palette
use constant CCyanWindow => pack('C*', 16,17,18,19,20,21,22,23);            # Cyan window palette
use constant CGrayWindow => pack('C*', 24,25,26,27,28,29,30,31);            # Grey window palette

#                                       ,---------- Passive Frame
#                                       !  ,-------- Passive Title
#                                       !  !  ,------ Active Frame
#                                       !  !  !  ,---- Active Title
#                                       !  !  !  !  ,-- Icons
use constant CFrame      => pack('C*',  1, 1, 2, 2, 3);                     # Frame palette

#                                       ,------ Page
#                                       !  ,---- Arrows
#                                       !  !  ,-- Indicator
use constant CScrollBar  => pack('C*',  4, 5, 5);                           # Scrollbar palette

#                                       ,---- Normal
#                                       !  ,-- Highlight
use constant CScroller   => pack('C*',  6, 7);                              # Scroller palette

#                                       ,---------- Active
#                                       !  ,-------- Inactive
#                                       !  !  ,------ Focused
#                                       !  !  !  ,---- Selected
#                                       !  !  !  !  ,-- Divider
use constant CListViewer => pack('C*', 26,26,27,28,29);                     # Listviewer palette

#                                          ,------------------ Frame Passive
#                                          !  ,---------------- Frame Active
#                                          !  !  ,-------------- Frame Icon
#                                          !  !  !  ,------------ ScrollBar Page
#                                          !  !  !  !  ,---------- ScrollBar Controls
#                                          !  !  !  !  !  ,-------- StaticText
#                                          !  !  !  !  !  !  ,------ Label Normal
#                                          !  !  !  !  !  !  !  ,---- Label Highlight
#                                          !  !  !  !  !  !  !  !  ,-- Label Shortcut
use constant CGrayDialog    => pack('C*', 32,33,34,35,36,37,38,39,40,
#                                          ,------------------ Button Normal
#                                          !  ,---------------- Button Default
#                                          !  !  ,-------------- Button Selected
#                                          !  !  !  ,------------ Button Disabled
#                                          !  !  !  !  ,---------- Button Shortcut
#                                          !  !  !  !  !  ,-------- Button Shadow
#                                          !  !  !  !  !  !  ,------ Cluster Normal
#                                          !  !  !  !  !  !  !  ,---- Cluster Selected
#                                          !  !  !  !  !  !  !  !  ,-- Cluster Shortcut
                                          41,42,43,44,45,46,47,48,49,
#                                          ,-------------- InputLine Normal
#                                          !  ,------------ InputLine Selected
#                                          !  !  ,---------- InputLine Arrows
#                                          !  !  !  ,-------- History Arrow
#                                          !  !  !  !  ,------ History Sides
#                                          !  !  !  !  !  ,---- HistoryWindow ScrollBar page
#                                          !  !  !  !  !  !  ,-- HistoryWindow ScrollBar controls
                                          50,51,52,53,54,55,56,
#                                          ,-------------- ListViewer Normal
#                                          !  ,------------ ListViewer Focused
#                                          !  !  ,---------- ListViewer Selected
#                                          !  !  !  ,-------- ListViewer Divider
#                                          !  !  !  !  ,------ InfoPane
#                                          !  !  !  !  !  ,---- Cluster disabled
#                                          !  !  !  !  !  !  ,-- Reserved
                                          57,58,59,60,61,62,63);
use constant CBlueDialog    => pack('C*', 64,65,66,67,68,69,70,71,72,
                                          73,74,75,76,77,78,79,80,81,
                                          82,83,84,85,86,87,88,
                                          89,90,91,92,92,94,95);
use constant CCyanDialog    => pack('C*', 96, 97, 98, 99,100,101,102,103,104,
                                         105,106,107,108,109,110,111,112,113,
                                         114,115,116,117,118,119,120,
                                         121,122,123,124,125,126,127);

#                                          ,-------- Text
#                                          !  ,------ ? Normal
#                                          !  !  ,---- ? Selected
#                                          !  !  !  ,-- ? Shortcut
use constant CStaticText    => pack('C*',  6, 7, 8, 9);
#                                          ,-------- Text Normal
#                                          !  ,------ Text Selected
#                                          !  !  ,---- Shortcut Normal
#                                          !  !  !  ,-- Shortcut Selected
use constant CLabel         => pack('C*',  7, 8, 9, 9);
#                                          ,---------------- Text Normal
#                                          !  ,-------------- Text Default
#                                          !  !  ,------------ Text Selected
#                                          !  !  !  ,---------- Text Disabled
#                                          !  !  !  !  ,-------- Shortcut Normal
#                                          !  !  !  !  !  ,------ Shortcut Default
#                                          !  !  !  !  !  !  ,---- Shortcut Selected
#                                          !  !  !  !  !  !  !  ,-- Reserved
use constant CButton        => pack('C*', 10,11,12,13,14,14,14,15);
#                                          ,------------ Text Normal
#                                          !  ,---------- Text Selected
#                                          !  !  ,-------- Shortcut Normal
#                                          !  !  !  ,------ Shortcut Selected
#                                          !  !  !  !  ,---- Text Disabled
#                                          !  !  !  !  !  ,-- ?
use constant CCluster       => pack('C*', 16,17,18,18,31, 6);
#                                          ,---------- Passive
#                                          !  ,-------- Active
#                                          !  !  ,------ Selected
#                                          !  !  !  ,---- Arrow
#                                          !  !  !  !  ,-- ? Disabled
use constant CInputLine     => pack('C*', 19,19,20,21,14);
#                                          ,---- Arrow
#                                          !  ,-- Sides
use constant CHistory       => pack('C*', 22,23);
#                                          ,-------------- Frame passiv
#                                          !  ,------------ Frame active
#                                          !  !  ,---------- Frame icon
#                                          !  !  !  ,-------- ScrollBar page area
#                                          !  !  !  !  ,------ ScrollBar controls
#                                          !  !  !  !  !  ,---- HistoryViewer normal text
#                                          !  !  !  !  !  !  ,-- HistoryViewer selected text
use constant CHistoryWindow => pack('C*', 19,19,21,24,25,19,20);
#                                          ,---------- Active
#                                          !  ,-------- Inactive
#                                          !  !  ,------ Focused
#                                          !  !  !  ,---- Selected
#                                          !  !  !  !  ,-- Divider
use constant CHistoryViewer => pack('C*',  6, 6, 7, 6, 6);

#                                          ,-- InfoPane
use constant CInfoPane      => pack('C*', 30);


use constant CHelpViewer => "\x06\x07\x08";
use constant CHelpWindow => "\x80\x81\x82\x83\x84\x85\x86\x87";

1;