package TV::Menus::MenuView;
# ABSTRACT: Abstract class for menu bars and menu boxes in Turbo Vision

use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TMenuView
  new_TMenuView
);

use Carp ();
use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Params::Check qw(
  check
  last_error
);
use Scalar::Util qw(
  blessed
  looks_like_number
  weaken
);

use TV::Drivers::Const qw( 
  :evXXXX
  :kbXXXX
);
use TV::Drivers::Util qw(
  ctrlToArrow
  getAltChar
);
use TV::Drivers::Event;
use TV::Objects::Rect;
use TV::Views::Const qw( 
  :cmXXXX
  hcNoContext
);
use TV::Views::Palette;
use TV::Views::View;
use TV::Menus::Const qw( 
  :menuAction
  cpMenuView
);
use TV::toolkit;

sub TMenuView() { __PACKAGE__ }
sub name() { 'TMenuView' }
sub new_TMenuView { __PACKAGE__->from(@_) }

extends TView;

# declare attributes
has parentMenu => ( is => 'bare' );
has menu       => ( is => 'ro' );
has current    => ( is => 'bare' );

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

my $lock_value = sub {
  Internals::SvREADONLY( $_[0] => 1 )
    if exists &Internals::SvREADONLY;
};

my $unlock_value = sub {
  Internals::SvREADONLY( $_[0] => 0 )
    if exists &Internals::SvREADONLY;
};

sub BUILDARGS {    # \%args (%args)
  my $class = shift;
  assert ( $class and !ref $class );
  local $Params::Check::PRESERVE_CASE = 1;
	my $args1 = $class->SUPER::BUILDARGS( @_ );
  my $args2 = STRICT ? check( {
    # check 'isa' (note: 'menu' and 'parentMenu' can be undefined)
    menu       => { allow => sub { !defined $_[0] or blessed $_[0] } },
    parentMenu => { allow => sub { !defined $_[0] or blessed $_[0] } },
  } => { @_ } ) || Carp::confess( last_error ) : { @_ };
  return { %$args1, %$args2 };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
	assert( @_ == 2 );
  assert ( blessed $self );
  $self->{eventMask} |= evBroadcast;
  weaken( $self->{parentMenu} )        if $self->{parentMenu};
  weaken( $self->{current} )           if $self->{current};
  $lock_value->( $self->{parentMenu} ) if STRICT;
  $lock_value->( $self->{current} )    if STRICT;
  return;
}

sub from {    # $obj ($bounds, |$aMenu|undef, |$aParent);
  my $class = shift;
  assert ( $class and !ref $class );
  assert ( @_ >= 1 && @_ <= 3 );
  SWITCH: for ( scalar @_ ) {
    $_ == 1 and return $class->new( bounds => $_[0] );
    $_ == 2 and return $class->new(
      bounds => $_[0], menu => $_[1], parentMenu => undef );
    $_ == 3 and return $class->new(
      bounds => $_[0], menu => $_[1], parentMenu => $_[2] );
  }
  return;
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
	assert( @_ == 2 );
  assert ( blessed $self );
  $unlock_value->( $self->{parentMenu} ) if STRICT;
  $unlock_value->( $self->{current} )    if STRICT;
  return;
}

# The following subroutine was taken from the framework
# "A modern port of Turbo Vision 2.0", which is licensed under MIT licence.
#
# Copyright 2019-2021 by magiblot <magiblot@hotmail.com>
#
# I<tmnuview.cpp>
sub execute {    # $int ()
  my ( $self ) = @_;
	assert( @_ == 1 );
  assert( blessed $self );
  my $autoSelect     = !!0;
  my $firstEvent     = !!1;
  my $action         = 0;
  my $result         = 0;
  my $itemShown      = undef;
  my $target         = undef;
  my $lastTargetItem = undef;
  my $r              = TRect->new();
  my $e              = TEvent->new();
  my $mouseActive    = !!0;

  $self->current( $self->{menu}{deflt} );
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
          # autoSelect makes it possible to open the selected submenu directly
          # on a MouseDown event. This should be avoided, however, when said
          # submenu was just closed by clicking on its name, or when this is
          # not a menu bar.
          if ( $self->{size}{y} == 1 ) {
            no warnings 'uninitialized';
            $autoSelect = !$self->{current}
              || $lastTargetItem != $self->{current};
          }
          # A submenu will close if the MouseDown event takes place on the
          # parent menu, except when this submenu has just been opened.
          elsif ( !$firstEvent && $self->$mouseInOwner( $e ) ) {
            $action = doReturn;
          }
        }
        else {
          $action = doReturn;
        }
        last;
      };
      $_ == evMouseUp and do {
        $self->$trackMouse( $e, $mouseActive );
        if ( $self->$mouseInOwner( $e ) ) {
          $self->current( $self->{menu}{deflt} );
        }
        elsif ( $self->{current} ) {
          if ( $self->{current}{name} ) {
            no warnings 'uninitialized';
            if ( $self->{current} != $lastTargetItem ) {
              $action = doSelect;
            }
            elsif ( $self->{size}{y} == 1 ) {
              # If a menu bar entry was closed, exit and stop listening
              # for events.
              $action = doReturn;
            }
            else {
              # MouseUp won't open up a submenu that was just closed by 
              # clicking on its name.
              $action = doNothing;
              # But the next one will.
              $lastTargetItem = undef;
            }
          } #/ if ( $self->{current}{...})
        } #/ elsif ( $self->{current} )
        elsif ( $mouseActive && !$self->mouseInView( $e->{mouse}{where} ) ) {
          $action = doReturn;
        }
        elsif ( $self->{size}{y} == 1 ) {
          # When MouseUp happens inside the Box but not on a highlightable
          # entry (e.g. on a margin, or a separator), either the default or the
          # first entry will be automatically highlighted. This was added in
          # Turbo Vision 2.0. But this doesn't make sense in a menu bar, which
          # was the original behavior.
          $self->current(
            $self->{menu}{deflt}
            ? $self->{menu}{deflt}
            : $self->{menu}{items}
          );
          $action = doNothing;
        } #/ elsif ( $self->{size}{y} ...)
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
        SWITCH: for my $key ( ctrlToArrow( $e->{keyDown}{keyCode} ) ) {
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
              $self->current( $self->{menu}{items} );
              $self->$trackKey( !!0 )
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
              $action = doSelect;
              $self->current( $p );
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
          $lastTargetItem = undef;
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
      # If a submenu was closed by clicking on its name, and the mouse is 
      # dragged to another menu entry, then the submenu will be opened the next 
      # time it is hovered over.
      if ( $lastTargetItem != $self->{current} ) {
        $lastTargetItem = undef;
      }

      if ( $itemShown != $self->{current} ) {
        $itemShown = $self->{current};
        $self->drawView();
      }
    }

    if ( ( $action == doSelect || ( $action == doNothing && $autoSelect ) )
      && $self->{current}
      && $self->{current}{name}
    ) {
      if ( $self->{current}{command} == 0 && !$self->{current}{disabled} ) {
        if ( $e->{what} & ( evMouseDown | evMouseMove ) ) {
          $self->putEvent( $e );
        }
        $r = $self->getItemRect( $self->{current} );
        $r->{a}{x} = $r->{a}{x} + $self->{origin}{x};
        $r->{a}{y} = $r->{b}{y} + $self->{origin}{y};
        $r->{b} = $self->{owner}{size};
        $r->{a}{x}-- 
          if $self->{size}{y} == 1;
        $target = $self->$topMenu()->newSubView( 
          $r, $self->{current}{subMenu}, $self 
        );
        $result = $self->{owner}->execView( $target );
        $self->destroy( $target );
        weaken( $lastTargetItem = $self->{current} );
        $self->{menu}->deflt( $self->{current} );
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

    $firstEvent = !!0;
  } while ( $action != doReturn );

  if ( $e->{what} != evNothing
    && ( $self->{parentMenu} || $e->{what} == evCommand )
  ) {
    $self->putEvent( $e );
  }
  if ( $self->{current} ) {
    $self->{menu}->deflt( $self->{current} );
    $self->current( undef );
    $self->drawView();
  }
  return $result;
} #/ sub execute

sub findItem {    # $menuItem|undef ($ch)
  my ( $self, $ch ) = @_;
	assert( @_ == 2 );
  assert ( blessed $self );
  assert ( defined $ch and !ref $ch );
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

sub getItemRect {    # $rect ($item|undef)
  my ( $self, $item ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( !defined $item or blessed $item );
  return TRect->new();
}

sub getHelpCtx {    # $int ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  my $c = $self;

  while ( $c 
    && ( !$c->{current}
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
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( blessed $self );
  $palette ||= TPalette->new( 
    data => cpMenuView, 
    size => length( cpMenuView ),
  );
  return $palette->clone();
}

sub handleEvent {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( blessed $event );
  if ( $self->{menu} ) {
    SWITCH: for ( $event->{what} ) {
      $_ == evMouseDown and do {
        $self->$do_a_select( $event );
        last;
      };
      $_ == evKeyDown and do {
        if ( $self->findItem( getAltChar( $event->{keyDown}{keyCode} ) ) ) {
          $self->$do_a_select( $event );
        }
        else {
          my $p = $self->hotKey( $event->{keyDown}{keyCode} );
          if ( $p && TView->commandEnabled( $p->{command} ) ) {
            $event->{what} = evCommand;
            $event->{message}{command} = $p->{command};
            $event->{message}{infoPtr} = undef;
            $self->putEvent( $event );
            $self->clearEvent( $event );
          }
        } #/ else [ if ( $self->findItem( ...))]
        last;
      };
      $_ == evCommand and do {
        if ( $event->{message}{command} == cmMenu ) {
          $self->$do_a_select( $event );
        }
        last;
      };
      $_ == evBroadcast and do {
        if ( $event->{message}{command} == cmCommandSetChanged ) {
          $self->drawView() 
            if $self->$updateMenu( $self->{menu} );
        }
        last;
      };
    }
  } #/ if ( $self->{menu} )
  return;
} #/ sub handleEvent

sub hotKey {    # $menuItem ($keyCode)
  my ( $self, $keyCode ) = @_;
  assert ( @_ == 2 );
  assert ( blessed $self );
  assert ( looks_like_number $keyCode );
  return $self->$findHotKey( $self->{menu}{items}, $keyCode );
}

sub newSubView {    # $menuView ($bounds, $aMenu, $aParentMenu)
  my ( $self, $bounds, $aMenu, $aParentMenu ) = @_;
  assert ( @_ == 4 );
  assert ( blessed $self );
  assert ( ref $bounds );
  assert ( !defined $aMenu       or blessed $aMenu );
  assert ( !defined $aParentMenu or blessed $aParentMenu );
  require TV::Menus::MenuBox;
  return TV::Menus::MenuBox->new(
    bounds     => $bounds,
    menu       => $aMenu,
    parentMenu => $aParentMenu,
  );
}

sub parentMenu {    # $menuView|undef (|$menuView|undef)
  my ( $self, $menuView ) = @_;
  assert ( @_ >= 1 && @_ <= 2 );
  assert ( blessed $self );
  assert ( !defined $menuView or blessed $menuView );
  if ( @_ == 2 ) {
    $unlock_value->( $self->{parentMenu} ) if STRICT;
    weaken $self->{parentMenu}
      if $self->{parentMenu} = $menuView;
    $lock_value->( $self->{parentMenu} ) if STRICT;
  }
  return $self->{parentMenu};
} #/ sub parentMenu

sub current {    # $menuItem|undef (|$menuItem|undef)
  my ( $self, $menuItem ) = @_;
  assert ( @_ >= 1 && @_ <= 2 );
  assert ( blessed $self );
  assert ( !defined $menuItem or blessed $menuItem );
  if ( @_ == 2 ) {
    $unlock_value->( $self->{current} ) if STRICT;
    weaken $self->{current}
      if $self->{current} = $menuItem;
    $lock_value->( $self->{current} ) if STRICT;
  }
  return $self->{current};
} #/ sub current

$nextItem = sub {    # void ()
  my $self = shift;
  $self->current(
    $self->{current}{next}
      ? $self->{current}{next}
      : $self->{menu}{items}
  );
  return;
};

$prevItem = sub {    # void ()
  my $self = shift;
  my $p;

  no warnings 'uninitialized';
  if ( ( $p = $self->{current} ) == $self->{menu}{items} ) {
    $p = undef;
  }

  do {
    $self->$nextItem();
  } while ( $self->{current}{next} != $p );
  return;
}; #/ $prevItem = sub

$trackKey = sub {    # void ($findNext)
  my ( $self, $findNext ) = @_;
  return
    unless $self->{current};

  do {
    if ( $findNext ) {
      $self->$nextItem();
    }
    else {
      $self->$prevItem();
    }
  } while ( !$self->{current}{name} );
  return;
}; #/ $trackKey = sub

$mouseInOwner = sub {    # $bool ($e)
  my ( $self, $e ) = @_;
  if ( !$self->{parentMenu} || $self->{parentMenu}{size}{y} != 1 ) {
    return !!0;
  }
  else {
    my $mouse = $self->{parentMenu}->makeLocal( $e->{mouse}{where} );
    my $r = $self->{parentMenu}->getItemRect( $self->{parentMenu}{current} );
    return $r->contains( $mouse );
  }
}; #/ $mouseInOwner = sub

$mouseInMenus = sub {    # $bool ($e)
  my ( $self, $e ) = @_;
  my $p = $self->{parentMenu};
  while ( $p && !$p->mouseInView( $e->{mouse}{where} ) ) {
    $p = $p->{parentMenu};
  }
  return defined $p;
};

$trackMouse = sub {    # void ($e, $mouseActive)
  my ( $self, $e, undef ) = @_;
  alias: for my $mouseActive ( $_[2] ) {
  my $mouse = $self->makeLocal( $e->{mouse}{where} );
  for (
    $self->current( $self->{menu}{items} );
    $self->{current};
    $self->current( $self->{current}{next} )
  ) {
    my $r = $self->getItemRect( $self->{current} );
    if ( $r->contains( $mouse ) ) {
      $mouseActive = !!1;
      return;
    }
  } #/ for ( $self->{current} ...)
  return;
  } #/ alias:
}; #/ sub

$topMenu = sub {    # $menuView ()
  my $self = shift;
  my $p    = $self;
  while ( $p->{parentMenu} ) {
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
            && $self->$updateMenu( $p->{subMenu} );
        }
        else {
          my $commandState = TView->commandEnabled( $p->{command} );
          no warnings 'uninitialized';
          if ( $p->{disabled} == $commandState ) {
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
  my $cmd = $self->{owner}->execView( $self );
  if ( $cmd && TView->commandEnabled( $cmd ) ) {
    $event->{what} = evCommand;
    $event->{message}{command} = $cmd;
    $event->{message}{infoPtr} = undef;
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
        && $p->{keyCode} == $keyCode
      ) {
        return $p;
      }
    } #/ if ( $p->{name} )
    $p = $p->{next};
  } #/ while ( $p )
  return undef;
}; #/ sub $findHotKey

1

__END__

=pod

=head1 NAME

TV::Menus::MenuView - defines the class TMenuView

=cut
