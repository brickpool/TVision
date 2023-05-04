use 5.014;
use warnings;
use Test::More;

if( $^O ne 'MSWin32' ) {
  plan skip_all => 'Test relevant only for Windows OS';
}
else {
  plan tests => 5;
}

use TurboVision::Drivers::Const qw( :smXXXX );
use TurboVision::Drivers::Win32::Screen qw( :all !:private );

sleep(1);

ok defined($screen_mode), 'defined screen mode';

init_video();
set_video_mode(SM_CO80);

is $screen_width,  80, 'screen width:  80';
is $screen_height, 25, 'screen height: 25';

sleep(1);
done_video();
sleep(1);

init_video();
set_video_mode(SM_CO80 | SM_FONT8X8);

is $screen_width,  80, 'screen width:  80';
is $screen_height, 50, 'screen height: 50';

sleep(1);
done_video();
sleep(1);

done_testing;
