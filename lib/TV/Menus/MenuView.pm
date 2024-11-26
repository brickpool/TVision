=pod

=head1 NAME

TV::Menus::MenuView - defines the class TMenuView

=cut

package TV::Menus::MenuView;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TMenuView
);

use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TV::Drivers::Const qw( 
  :evXXXX
  kbNoKey
  kbUp
  kbDown
  kbLeft
  kbRight
  kbHome
  kbEnd
  kbEnter
  kbEsc
);
use TV::Drivers::Util qw(
  ctrlToArrow
  getAltChar
);
use TV::Drivers::Event;
use TV::Objects::Rect;
use TV::Views::Const qw( 
  cmMenu
  cmCommandSetChanged
  hcNoContext
);
use TV::Views::Palette;
use TV::Views::View;
use TV::Menus::Const qw( 
  :menuAction
  cpMenuView
);

sub TMenuView() { __PACKAGE__ }
sub name() { TMenuView }

use base TView;

# predeclare attributes
use fields qw(
  parentMenu
  menu
  current
);

# predeclare private methods
my (
  $nextItem,
  $prevItem,
  $trackKey,
  $mouseInOwner,
  $mouseInMenus,
  $trackMouse,
  $topMenu,
  $updateMenu,
  $do_a_select,
  $findHotKey,
);

sub BUILDARGS {    # \%args (%args)
  my ( $class, %args ) = @_;
  assert ( $class and !ref $class );
  $args{menu}       = delete $args{aMenu};
  $args{parentMenu} = delete $args{aParent};
  return $class->SUPER::BUILDARGS( %args );
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( blessed $self );
  assert ( !defined $self->{menu}       or blessed $self->{menu} );
  assert ( !defined $self->{parentMenu} or blessed $self->{parentMenu} );
  $self->{eventMask} |= evBroadcast;
  return;
}

sub execute {    # $cmd ()
  my $self        = shift;
  my $autoSelect  = !!0;
  my $action      = 0;
  my $result      = 0;
  my $itemShown   = 0;
  my $target      = undef;
  my $r           = TRect->new();
  my $e           = TEvent->new();
  my $mouseActive = !!0;

  $self->{current} = $self->{menu}{deflt};
  $mouseActive = 0;
  do {
    $action = doNothing;
    $self->getEvent( $e );
    SWITCH: for ( $e->{what} ) {
      $_ == evMouseDown and do {
        if ( $self->mouseInView( $e->{mouse}{where} ) 
          || $self->$mouseInOwner( $e ) 
        ) {
          $self->$trackMouse( $e, $mouseActive );
          $autoSelect = !!1 
            if $self->{size}{y} == 1;
        }
        else {
          $action = doReturn;
        }
        last;
      };
      $_ == evMouseUp and do {
        $self->$trackMouse( $e, $mouseActive );
        if ( $self->$mouseInOwner( $e ) ) {
          $self->{current} = $self->{menu}{deflt};
        }
        elsif ( $self->{current} && $self->{current}{name} ) {
          $action = doSelect;
        }
        elsif ( $mouseActive ) {
          $action = doReturn;
        }
        else {
          $self->{current} = $self->{menu}{deflt};
          $self->{current} = $self->{menu}{items}
            unless $self->{current};
          $action = doNothing;
        }
        last;
      };
      $_ == evMouseMove and do {
        if ( $e->{mouse}{buttons} ) {
          $self->$trackMouse( $e, $mouseActive );
          if ( !( $self->mouseInView( $e->{mouse}{where} ) 
              || $self->$mouseInOwner( $e ) 
            )
            && $self->$mouseInMenus( $e ) )
          {
            $action = doReturn;
          }
        }
        last;
      };
      $_ == evKeyDown and do {
        SWITCH: for( my $key = ctrlToArrow( $e->{keyDown}{keyCode} ) ) {
          $key == kbUp || 
          $key == kbDown and do {
            if ( $self->{size}{y} != 1 ) {
              $self->$trackKey( $key == kbDown );
            }
            elsif ( $e->{keyDown}{keyCode} == kbDown ) {
              $autoSelect = !!1;
            }
            last;
          };
          $key == kbLeft || 
          $key == kbRight and do {
            if ( !$self->{parentMenu} ) {
              $self->$trackKey( $key == kbRight );
            }
            else {
              $action = doReturn;
            }
            last;
          };
          $key == kbHome || 
          $key == kbEnd and do {
            if ( $self->{size}{y} != 1 ) {
              $self->{current} = $self->{menu}{items};
              $self->$trackKey( 0 ) 
                if $e->{keyDown}{keyCode} == kbEnd;
            }
            last;
          };
          $key == kbEnter and do {
            $autoSelect = !!1 
              if $self->{size}{y} == 1;
            $action = doSelect;
            last;
          };
          $key == kbEsc and do {
            $action = doReturn;
            $self->clearEvent( $e )
              if !$self->{parentMenu} || $self->{parentMenu}{size}{y} != 1;
            last;
          };
          DEFAULT: {
            $target = $self;
            my $ch = getAltChar( $e->{keyDown}{keyCode} );
            $ch = $e->{keyDown}{charScan}{charCode} 
              unless $ch;
            $target = $self->$topMenu()
              if $ch;
            my $p = $target->findItem( $ch );
            if ( !$p ) {
              $p = $self->$topMenu()->hotKey( $e->{keyDown}{keyCode} );
              if ( $p && TView->commandEnabled( $p->{command} ) ) {
                $result = $p->{command};
                $action = doReturn;
              }
            }
            elsif ( $target == $self ) {
              $autoSelect = !!1 
                if $self->{size}{y} == 1;
              $action          = doSelect;
              $self->{current} = $p;
            }
            elsif ( $self->{parentMenu} != $target 
              || $self->{parentMenu}{current} != $p 
            ) {
              $action = doReturn;
            }
          }
        }
        last;
      };
      $_ == evCommand and do {
        if ( $e->{message}{command} == cmMenu ) {
          $autoSelect = !!0;
          $action = doReturn
            if $self->{parentMenu};
        }
        else {
          $action = doReturn;
        }
        last;
      };
    }

    { 
      no warnings 'uninitialized';
      if ( $itemShown != $self->{current} ) {
        $itemShown = $self->{current};
        $self->drawView();
      }
    }

    if ( ( $action == doSelect || ( $action == doNothing && $autoSelect ) )
      && $self->{current}
      && $self->{current}{name}
    ) {
      if ( $self->{current}{command} == 0 ) {
        if ( $e->{what} & ( evMouseDown | evMouseMove ) ) {
          $self->putEvent( $e );
        }
        $r = $self->getItemRect( $self->{current} );
        $r->{a}{x} += $self->{origin}{x};
        $r->{a}{y} += $self->{origin}{y};
        $r->{b} = $self->{owner}{size};
        $r->{a}{x}-- 
          if $self->{size}{y} == 1;
        $target = $self->$topMenu()->newSubView( 
          $r, $self->{current}{subMenu}, $self 
        );
        $result = $self->{owner}->execView( $target );
        $self->destroy( $target );
      } #/ if ( $self->{current}{...})
      elsif ( $action == doSelect ) {
        $result = $self->{current}{command};
      }
    } #/ if ( ( $action == doSelect...))

    if ( $result && TView->commandEnabled( $result ) ) {
      $action = doReturn;
      $self->clearEvent( $e );
    }
    else {
      $result = 0;
    }
  } while ( $action != doReturn );

  if ( $e->{what} != evNothing
    && ( $self->{parentMenu} || $e->{what} == evCommand )
  ) {
    $self->putEvent( $e );
  }
  if ( $self->{current} ) {
    $self->{menu}{deflt} = $self->{current};
    $self->{current} = undef;
    $self->drawView();
  }
  return $result;
} #/ sub execute

sub findItem {    # $menuItem|undef ($ch)
  my ( $self, $ch ) = @_;
  assert ( blessed $self );
  $ch = uc( $ch );
  my $p = $self->{menu}{items};
  while ( $p ) {
    if ( $p->{name} && !$p->{disabled} ) {
      my $loc = index( $p->{name}, '~' );
      if ( $loc != -1 && uc( substr( $p->{name}, $loc + 1, 1 ) ) eq $ch ) {
        return $p;
      }
    }
    $p = $p->{next};
  }
  return undef;
} #/ sub findItem

sub getItemRect {    # $rect ($menuItem)
  assert ( @_ == 2 );
  assert ( blessed $_[0] );
  assert ( !defined $_[1] or blessed $_[1] );
  return TRect->new();
}

sub getHelpCtx {    # $int ()
  my $self = shift;
  assert ( blessed $self );
  my $c    = $self;

  while ( $c && ( !$c->{current}
               || $c->{current}{helpCtx} == hcNoContext
               || !$c->{current}{name} )
  ) {
    $c = $c->{parentMenu};
  }

  return $c
    ? $c->{current}{helpCtx}
    : hcNoContext;
} #/ sub getHelpCtx

my $palette;
sub getPalette {    # $palette ()
  my $self = shift;
  assert ( blessed $self );
  $palette ||= TPalette->new( cpMenuView, length( cpMenuView ) );
  return $palette;
}

sub handleEvent {    # void ($event)
  my ( $self, $event ) = @_;
  if ( $self->{menu} ) {
    if ( $event->{what} == evMouseDown ) {
      $self->$do_a_select( $event );
    }
    elsif ( $event->{what} == evKeyDown ) {
      if ( $self->findItem( getAltChar( $event->{keyDown}{keyCode} ) ) ) {
        $self->$do_a_select( $event );
      }
      else {
        my $p = $self->hotKey( $event->{keyDown}{keyCode} );
        if ( $p && TView->commandEnabled( $p->{command} ) ) {
          $event->{what}             = evCommand;
          $event->{message}{command} = $p->{command};
          $event->{message}{infoPtr} = undef;
          $self->putEvent( $event );
          $self->clearEvent( $event );
        }
      } #/ else [ if ( $self->findItem( ...))]
    } #/ elsif ( $event->{what} eq...)
    elsif ( $event->{what} == evCommand ) {
      if ( $event->{message}{command} == cmMenu ) {
        $self->$do_a_select( $event );
      }
    }
    elsif ( $event->{what} == evBroadcast ) {
      if ( $event->{message}{command} == cmCommandSetChanged ) {
        $self->drawView() 
          if $self->$updateMenu( $self->{menu} );
      }
    }
  } #/ if ( $self->{menu} )
  return;
} #/ sub handleEvent

sub hotKey {    # $menuItem ($keyCode)
  my ( $self, $keyCode ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $keyCode );
  return $self->$findHotKey( $self->{menu}{items}, $keyCode );
}

sub newSubView {    # $menuItem ($bounds, $aMenu, $aParentMenu)
  my ( $self, $bounds, $aMenu, $aParentMenu ) = @_;
  assert ( blessed $self );
  assert ( ref $bounds );
  assert ( !defined $aMenu       or blessed $aMenu );
  assert ( !defined $aParentMenu or blessed $aParentMenu );
  return TMenuBox->new( $bounds, $aMenu, $aParentMenu );
}

$nextItem = sub {    # void ()
  my $self = shift;
  if ( !( $self->{current} = $self->{current}{next} ) ) {
    $self->{current} = $self->{menu}{items};
  }
  return;
};

$prevItem = sub {    # void ()
  my $self = shift;
  my $p;

  if ( ( $p = $self->{current} ) == $self->{menu}{items} ) {
    $p = 0;
  }

  do {
    $self->nextItem();
  } while ( $self->{current}{next} != $p );
  return;
}; #/ $prevItem = sub

$trackKey = sub {    # void ($findNext)
  my ( $self, $findNext ) = @_;
  return if $self->{current} == 0;

  do {
    if ( $findNext ) {
      $self->nextItem();
    }
    else {
      $self->prevItem();
    }
  } while ( $self->{current}{name} == 0 );
  return;
}; #/ $trackKey = sub

$mouseInOwner = sub {    # $bool ($e)
  my ( $self, $e ) = @_;
  if ( $self->{parentMenu} == 0 || $self->{parentMenu}{size}{y} != 1 ) {
    return !!0;
  }
  else {
    my $mouse = $self->{parentMenu}->makeLocal( $e->{mouse}{where} );
    my $r     = $self->{parentMenu}->getItemRect( $self->{parentMenu}{current} );
    return $r->contains( $mouse );
  }
}; #/ $mouseInOwner = sub

$mouseInMenus = sub {    # $bool ($e)
  my ( $self, $e ) = @_;
  my $p = $self->{parentMenu};
  while ( $p != 0 && !$p->mouseInView( $e->{mouse}{where} ) ) {
    $p = $p->{parentMenu};
  }
  return $p != 0;
};

$trackMouse = sub {    # void ($e, $mouseActive)
	my ( $self, $e, $mouseActive ) = @_;
	my $mouse = $self->makeLocal( $e->{mouse}{where} );
	for (
		$self->{current} = $self->{menu}{items};
		$self->{current};
		$self->{current} = $self->{current}{next}
		)
	{
		my $r = $self->getItemRect( $self->{current} );
		if ( $r->contains( $mouse ) ) {
			$mouseActive = !!1;
			return;
		}
	} #/ for ( $self->{current} ...)
  return;
}; #/ sub

$topMenu = sub {    # $menuView ()
  my $self = shift;
  my $p    = $self;
  while ( $p->{parentMenu} != 0 ) {
    $p = $p->{parentMenu};
  }
  return $p;
};

$updateMenu = sub {    # $bool ($menu)
  my ( $self, $menu ) = @_;
  my $res = !!0;
  if ( $menu ) {
    for ( my $p = $menu->{items} ; $p ; $p = $p->{next} ) {
      if ( $p->{name} ) {
        if ( $p->{command} == 0 ) {
          $res = !!1
            if $p->{subMenu}
            && $self->updateMenu( $p->{subMenu} );
        }
        else {
          no warnings 'uninitialized';
          my $commandState = TView->commandEnabled( $p->{command} );
          if ( 0+ $p->{disabled} == 0+ $commandState ) {
            $p->{disabled} = !$commandState;
            $res = !!1;
          }
        }
      } #/ if ( $p->{name} )
    } #/ for ( my $p = $menu->{items...})
  } #/ if ( $menu )
  return $res;
}; #/ $updateMenu = sub

$do_a_select = sub {    # void ($event)
  my ( $self, $event ) = @_;
  $self->putEvent( $event );
  $event->{message}{command} = $self->{owner}->execView( $self );
  if ( $event->{message}{command}
    && TView->commandEnabled( $event->{message}{command} ) )
  {
    $event->{what} = evCommand;
    $event->{message}{infoPtr} = 0;
    $self->putEvent( $event );
  }
  $self->clearEvent( $event );
  return;
}; #/ $do_a_select = sub

$findHotKey = sub {    # $menuItem|undef ($p, $keyCode)
  my ( $self, $p, $keyCode ) = @_;
  while ( $p ) {
    if ( $p->{name} ) {
      if ( $p->{command} == 0 ) {
        my $T = $self->$findHotKey( $p->{subMenu}{items}, $keyCode );
        return $T 
          if $T;
      }
      elsif ( !$p->{disabled}
        && $p->{keyCode} != kbNoKey
        && $p->{keyCode} == $keyCode )
      {
        return $p;
      }
    } #/ if ( $p->{name} )
    $p = $p->{next};
  } #/ while ( $p )
  return undef;
}; #/ sub $findHotKey

1
