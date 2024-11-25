=pod

=head1 NAME

TV::Views::View - defines the class TGroup

=cut

package TV::Views::Group;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
  TGroup
);

use Data::Alias;
use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : 'off';
use Scalar::Util qw(
  blessed
  looks_like_number
  weaken
  isweak
);

use TV::Objects::Point;
use TV::Drivers::Const qw(
  :evXXXX
);
use TV::Drivers::Event;
use TV::Views::Const qw(
  :cmXXXX
  :evXXXX
  :hcXXXX
  :ofXXXX
  :phXXXX
  :sfXXXX
  :smXXXX
);
use TV::Views::CommandSet;
use TV::Views::View;

sub TGroup() { __PACKAGE__ }
sub name() { 'TGroup' }

use base TView;

# predeclare global variables
our $TheTopView;
our $ownerGroup;
{
  no warnings 'once';
  alias TGroup->{TheTopView} = $TheTopView;
  alias TGroup->{ownerGroup} = $ownerGroup;
}

# predeclare attributes
use fields qw(
  last
  phase
  current
  buffer
  lockFlag
  endState
  clip
);

# use own accessors
use subs qw(
  current
);

# predeclare private methods
my (
  $invalid,
  $focusView,
  $selectView,
  $findNext,
);

my $lock_value = sub {
  Internals::SvREADONLY( $_[0] => 1 )
    if exists &Internals::SvREADONLY;
};

my $unlock_value = sub {
  Internals::SvREADONLY( $_[0] => 0 )
    if exists &Internals::SvREADONLY;
};

sub BUILD {    # void (| \%args)
  my ( $self, $args ) = @_;
  assert ( blessed $self );
  assert ( defined $self->{options} );
  my %default = (
    last      => undef,
    phase     => phFocused,
    current   => undef,
    buffer    => undef,
    lockFlag  => 0,
    endState  => 0,
    eventMask => 0xffff,
  );
  map { $self->{$_} = $default{$_} }
    grep { !defined $self->{$_} }
      keys %default;
  $self->{options} |= ofSelectable | ofBuffered;
  $self->{clip} ||= $self->getExtent();
  $lock_value->( $self->{current} ) if STRICT;
  return;
} #/ sub BUILD

sub DEMOLISH {    # void ()
  my $self = shift;
  assert ( blessed $self );
  $unlock_value->( $self->{current} ) if STRICT;
  $self->shutDown();
  return;
}

sub shutDown {    # void ()
  my $self = shift;
  assert ( blessed $self );
  my $p = $self->{last};
  if ( $p ) {
    weaken $p;
    do {
      $p->hide();
      weaken( $p = $p->prev() );
    } while ( $p && $p != $self->{last} );

    while ( $p && $self->{last} ) {
      weaken( my $T = $p->prev() );
      $self->destroy( $p );
      weaken( $p = $T ); 
    }
  } #/ if ( $p )
  $self->freeBuffer();
  $self->current( undef );
  $self->SUPER::shutDown();
  return;
} #/ sub shutDown

sub execView {    # $int ()
  my ( $self, $p ) = @_;
  assert ( blessed $self );
  assert ( !defined $p or blessed $p );
  assert ( @_ == 2 );
  return cmCancel
    unless $p;

  my $saveOptions  = $p->{options};
  my $saveOwner    = $p->{owner};
  my $saveTopView  = $TheTopView;
  my $saveCurrent  = $self->current();
  my $saveCommands = TCommandSet->new();
  $self->getCommands( $saveCommands );
  $TheTopView = $p;
  $p->{options} &= ~ofSelectable;
  $p->setState( sfModal, !!1 );
  $self->setCurrent( $p, enterSelect );
  $self->insert( $p )
    unless $saveOwner;
  my $retval = $p->execute();
  $self->remove( $p )
    unless $saveOwner;
  $self->setCurrent( $saveCurrent, leaveSelect );
  $p->setState( sfModal, !!0 );
  $p->{options} = $saveOptions;
  $TheTopView = $saveTopView;
  $self->setCommands( $saveCommands );
  return $retval;
} #/ sub execView

sub execute {    # $int ()
  my $self = shift;
  assert ( blessed $self );
  do {
    $self->{endState} = 0;
    do {
      my $e = TEvent->new();
      $self->getEvent( $e );
      $self->handleEvent( $e );
      if ( $e->{what} != evNothing ) {
        $self->eventError( $e );
      }
    } while ( !$self->{endState} );
  } while ( !$self->valid( $self->{endState} ) );
  return $self->{endState};
} #/ sub execute

my $doAwaken = sub {    # void ($v, $p)
  $_[0]->awaken();
  return;
};

sub awaken {    # void ()
  my $self = shift;
  assert ( blessed $self );
  $self->forEach( $doAwaken, undef );
  return;
}

sub insertView {    # void ($self, $p, $Target|undef)
  my ( $self, $p, $Target ) = @_;
  assert ( blessed $self );
  assert ( blessed $p );
  assert ( !defined $Target or blessed $Target );
  assert ( @_ == 3 );
  $p->owner( $self );
  if ( $Target ) {
    $Target = $Target->prev();
    $p->next( $Target->{next} );
    $Target->next( $p );
  }
  else {
    if ( !$self->{last} ) {
      $p->next( $p );
    }
    else {
      $p->next( $self->{last}{next} );
      $self->{last}->next( $p );
    }
    $self->{last} = $p;
  } #/ else [ if ( $Target ) ]
  # Note: The $p->{next} field should refer to $p, 
  # but this could generate a cyclical reference.
  $p = $self->{last}->prev();
  if ( !isweak $p->{next} ) {
    $unlock_value->( $p->{next} ) if STRICT;
    weaken $p->{next};
    $lock_value->( $p->{next} ) if STRICT;
  }
  return;
} #/ sub insertView

sub remove {    # void ($p)
  my ( $self, $p ) = @_;
  assert ( blessed $self );
  assert ( !defined $p or blessed $p );
  assert ( @_ == 2 );
  if ( $p ) {
    my $saveState = $p->{state};
    $p->hide();
    $self->removeView( $p );
    $p->owner( undef );
    $p->next( undef );
    if ( $saveState & sfVisible ) {
      $p->show();
    }
  } #/ if ( $p )
  return;
} #/ sub remove

# The following subroutine was taken from the framework
# "A modern port of Turbo Vision 2.0", which is licensed under MIT licence.
#
# Copyright 2019-2021 by magiblot <magiblot@hotmail.com>
#
# I<tgrmv.cpp>
sub removeView {    # void ($p)
  no warnings qw( uninitialized numeric );
  my ( $self, $p ) = @_;
  assert ( blessed $self );
  assert ( blessed $p );
  if ( $self->{last} ) {
    my $s = $self->{last};
    while ( $s->{next} != $p ) {
      return
        if $s->{next} == $self->{last};
      $s = $s->{next};
    }
    $s->next( $p->next );
    if ( $p == $self->{last} ) {
      $self->{last} = $p == $p->{next} ? undef : $s;
    }
    # Note: The $p->{next} field should refer to $p, 
    # but this could generate a cyclical reference.
    $p = $self->{last}->prev() 
      if $p != $p->{next};
    if ( !isweak $p->{next} ) {
      $unlock_value->( $p->{next} ) if STRICT;
      weaken $p->{next};
      $lock_value->( $p->{next} ) if STRICT;
    }
  } #/ if ( $self->{last} )
  return;
} #/ sub removeView

sub resetCurrent {    # void ()
  my $self = shift;
  assert ( blessed $self );
  $self->setCurrent( $self->firstMatch( sfVisible, ofSelectable ),
    normalSelect );
  return;
}

sub setCurrent {    # void ($p, $mode)
  no warnings qw( uninitialized numeric );
  my ( $self, $p, $mode ) = @_;
  assert ( blessed $self );
  assert ( !defined $p or blessed $p );
  assert ( looks_like_number $mode );
  return 
    if $self->current() == $p;

  $self->lock();
  $self->$focusView( $self->current(), 0 );
  $self->current()->setState( sfSelected, 0 )
    if $mode != enterSelect 
    && $self->current();
  $p->setState( sfSelected, 1 ) 
    if $mode != leaveSelect && $p;
  $p->setState( sfFocused,  1 ) 
    if ( $self->{state} & sfFocused ) && $p;
  $self->current( $p );
  $self->unlock();
  return;
} #/ sub setCurrent

sub selectNext {    # void ($forwards)
  my ( $self, $forwards ) = @_;
  assert ( blessed $self );
  assert ( !defined $forwards or !ref $forwards );
  assert ( @_ == 2 );
  if ( $self->current() ) {
    my $p = $self->$findNext( $forwards );
    $p->select() if $p;
  }
  return;
} #/ sub selectNext

sub firstThat {    # $view|undef (\&func, $args|undef)
  no warnings qw( uninitialized numeric );
  my ( $self, $func, $args ) = @_;
  assert ( blessed $self );
  assert ( ref $func );
  assert ( @_ == 3 );
  my $temp = $self->{last};
  return undef
    unless $temp;

  do {
    $temp = $temp->{next};
    return $temp
      if $func->( $temp, $args );
  } while ( $temp != $self->{last} );
  return undef;
} #/ sub firstThat

sub focusNext {    # $bool ($forwards)
  my ( $self, $forwards ) = @_;
  assert ( blessed $self );
  assert ( !defined $forwards or !ref $forwards );
  assert ( @_ == 2 );
  my $p = $self->$findNext( $forwards );
  return $p ? $p->focus() : !!1;
}

sub forEach {    # void (\&func, $args|undef)
  no warnings qw( uninitialized numeric );
  my ( $self, $func, $args ) = @_;
  assert ( blessed $self );
  assert ( ref $func );
  assert ( @_ == 3 );
  weaken( my $term = $self->{last} );
  weaken( my $temp = $self->{last} );
  return 
    unless $temp;

  weaken( my $next = $temp->{next} );
  do {
    weaken( $temp = $next );
    weaken( $next = $temp->{next} );
    $func->( $temp, $args );
  } while ( $temp != $term );
  return;
} #/ sub forEach

sub insert {    # void ($p)
  my ( $self, $p ) = @_;
  assert ( blessed $self );
  assert ( !defined $p or blessed $p );
  assert ( @_ == 2 );
  $self->insertBefore( $p, $self->first() );
  return;
}

sub insertBefore {    # void ($self, $p, $Target|undef)
  no warnings qw( uninitialized numeric );
  my ( $self, $p, $Target ) = @_;
  assert ( blessed $self );
  assert ( blessed $p );
  assert ( !defined $Target or blessed $Target );
  assert ( @_ == 3 );
  if ( $p && !$p->{owner} && ( !$Target || $Target->{owner} == $self ) ) {
    $p->{origin}{x} = ( $self->{size}{x} - $p->{size}{x} ) >> 1
      if $p->{options} & ofCenterX;
    $p->{origin}{y} = ( $self->{size}{y} - $p->{size}{y} ) >> 1
      if $p->{options} & ofCenterY;
    my $saveState = $p->{state};
    $p->hide();
    $self->insertView( $p, $Target );
    $p->show()
      if $saveState & sfVisible;
    $p->setState( sfActive, !!1 )
      if $saveState & sfActive;
  } #/ if ( $p && !$p->owner(...))
} #/ sub insertBefore

sub current {    # $view|undef (|$view|undef)
  my ( $self, $view ) = @_;
  assert ( blessed $self );
  assert ( !defined $view or blessed $view );
  if ( @_ == 2 ) {
    $unlock_value->( $self->{current} ) if STRICT;
    weaken $self->{current}
      if $self->{current} = $view;
    $lock_value->( $self->{current} ) if STRICT;
  }
  return $self->{current};
} #/ sub current

sub at {    # $view|undef ($index)
  my ( $self, $index ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $index );
  my $temp = $self->{last};
  while ( $index-- > 0 ) {
    $temp = $temp->{next};
  }
  return $temp;
} #/ sub at

sub firstMatch {    # $view|undef ($aState, $aOptions)
  no warnings qw( uninitialized numeric );
  my ( $self, $aState, $aOptions ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $aState );
  assert ( looks_like_number $aOptions );
  return undef 
    unless $self->{last};

  my $temp = $self->{last};
  while ( 1 ) {
    return $temp
      if ( $temp->{state} & $aState ) == $aState
      && ( $temp->{options} & $aOptions ) == $aOptions;
    $temp = $temp->{next};
    return undef 
      if $temp == $self->{last};
  }
} #/ sub firstMatch

sub indexOf {    # $int ($p)
  no warnings qw( uninitialized numeric );
  my ( $self, $p ) = @_;
  assert ( blessed $self );
  assert ( blessed $p );
  return 0 
    unless $self->{last};

  my $index = 0;
  my $temp  = $self->{last};
  do {
    $index++;
    $temp = $temp->{next};
  } while ( $temp != $p && $temp != $self->{last} );
  return $temp == $p ? $index : 0;
} #/ sub indexOf

sub matches {    # $bool ($p)
  ...
}

sub first {    # $view|undef ()
  my $self = shift;
  assert ( blessed $self );
  return $self->{last} ? $self->{last}{next} : undef;
}

my $doExpose = sub {    # void ($p, \$enable)
  my ( $p, $enable ) = @_;
  $p->setState( sfExposed, $$enable )
    if $p->state & sfVisible;
  return;
};

my $doSetState = sub {    # void ($p, \%b)
  my ( $p, $b ) = @_;
  $p->setState( $b->{st}, $b->{en} );
  return;
};

sub setState {    # void ($aState, $enable)
  my ( $self, $aState, $enable ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $aState );
  assert ( !defined $enable or !ref $enable );
  assert ( @_ == 3 );
  my $sb = {
    st => $aState, 
    en => $enable,
  };

  $self->SUPER::setState( $aState, $enable );

  if ( $aState & ( sfActive | sfDragging ) ) {
    $self->lock();
    $self->forEach( $doSetState, $sb );
    $self->unlock();
  }

  if ( $aState & sfFocused ) {
    $self->current()->setState( sfFocused, $enable ) 
      if $self->current();
  }

  if ( $aState & sfExposed ) {
    $self->forEach( $doExpose, \$enable );
    $self->freeBuffer() 
      unless $enable;
  }
  return;
} #/ sub setState

my $doHandleEvent = sub {    # void ($p, \%s)
  my ( $p, $s ) = @_;
  return unless $p;
  return
    if ( $p->{state} & sfDisabled )
    && ( $s->{event}{what} & ( positionalEvents | focusedEvents ) );

  SWITCH: for ( $s->{grp}{phase} ) {
    $_ == phPreProcess and do {
      return
        unless $p->{options} & ofPreProcess;
      last;
    };
    $_ == phPostProcess and do {
      return
        unless $p->{options} & ofPostProcess;
      last;
    };
  } #/ SWITCH: for ( $s->{grp}{phase} )
  $p->handleEvent( $s->{event} )
    if $s->{event}{what} & $p->{eventMask};
  return;
}; #/ $doHandleEvent = sub

my $hasMouse = sub {    # $bool ($p, $s)
  my ( $p, $s ) = @_;
  return $p->containsMouse( $s );
};

sub handleEvent {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( blessed $self );
  assert ( blessed $event );
  $self->SUPER::handleEvent( $event );

  my $hs = { 
    event => $event, 
    grp => $self
  };

  if ( $event->{what} & focusedEvents ) {
    $self->{phase} = phPreProcess;
    $self->forEach( $doHandleEvent, $hs );

    $self->{phase} = phFocused;
    $doHandleEvent->( $self->current(), $hs );

    $self->{phase} = phPostProcess;
    $self->forEach( $doHandleEvent, $hs );
  } #/ if ( $event->{what} & ...)
  else {
    $self->{phase} = phFocused;
    if ( $event->{what} & positionalEvents ) {
      # get pointer to topmost view holding mouse
      my $p = $self->firstThat( $hasMouse, $event );
      if ( $p ) {
        # we have a view; send event to it
        $doHandleEvent->( $p, $hs );
      }
      elsif ( $event->{what} == evMouseDown ) {
        # it was a mouse click and we don't have a view,
        # so sound a beep.
        if ( eval { require Win32::Sound } ) {
          Win32::Sound::Play("SystemDefault");
        } 
        else {
          # May not work, depending on the nature of the terminal.
          print "\a";
        }
      }
    } #/ if ( $event->{what} & ...)
    else {
      $self->forEach( $doHandleEvent, $hs );
    }
  } #/ else [ if ( $event->{what} & ...)]
  return;
} #/ sub handleEvent

sub drawSubViews {    # void ($p|undef, $bottom|undef)
  no warnings qw( uninitialized numeric );
  my ( $self, $p, $bottom ) = @_;
  assert ( blessed $self );
  assert ( !defined $p or blessed $p );
  assert ( !defined $bottom or blessed $bottom );
  assert ( @_ == 3 );
  while ( $p != $bottom ) {
    $p->drawView();
    $p = $p->nextView();
  }
  return;
} #/ sub drawSubViews

my $doCalcChange = sub {    # void ($p, $d)
  my ( $p, $d ) = @_;
  my $r;
  $p->calcBounds( $r, $d );
  $p->changeBounds( $r );
  return;
};

sub changeBounds {    # void ($self, $bounds)
  my ( $self, $bounds ) = @_;
  assert ( blessed $self );
  assert ( blessed $bounds );
  my $d = TPoint->new(
    x => ( $bounds->{b}{x} - $bounds->{a}{x} ) - $self->{size}{x},
    y => ( $bounds->{b}{y} - $bounds->{a}{y} ) - $self->{size}{y},
  );
  if ( $d->{x} == 0 && $d->{y} == 0 ) {
    $self->setBounds( $bounds );
    $self->drawView();
  }
  else {
    $self->freeBuffer();
    $self->setBounds( $bounds );
    $self->{clip} = $self->getExtent();
    $self->getBuffer();
    $self->lock();
    $self->forEach( $doCalcChange, $d );
    $self->unlock();
  }
  return;
} #/ sub changeBounds

my $addSubviewDataSize = sub {    # void ($p, $T)
  my ( $p, $T ) = @_;
  $$T += $p->dataSize();
};

sub dataSize {    # $int ()
  my $self = shift;
  assert ( blessed $self );
  my $T = 0;
  $self->forEach( $addSubviewDataSize, \$T );
  return $T;
}

sub getData {    # void (\@rec)
  my ( $self, $rec ) = @_;
  assert ( blessed $self );
  assert ( ref $rec );
  my $i = 0;
  if ( $self->{last} ) {
    my $v = $self->{last};
    do {
      $v->getData( alias [ @$rec[ $i .. $#$rec ] ] );
      $i += $v->dataSize();
      $v = $v->prev();
    } while ( $v != $self->{last} );
  }
  return;
} #/ sub getData

sub setData {    # void (\@rec)
  my ( $self, $rec ) = @_;
  assert ( blessed $self );
  assert ( ref $rec );
  my $i = 0;
  if ( $self->{last} ) {
    my $v = $self->{last};
    do {
      $v->setData( alias [ @$rec[ $i .. $#$rec ] ] );
      $i += $v->dataSize();
      $v = $v->prev();
    } while ( $v != $self->{last} );
  }
  return;
} #/ sub setData

sub draw {    # void ()
  my $self = shift;
  assert ( blessed $self );
  if ( !$self->{buffer} ) {
    $self->getBuffer();
    if ( $self->{buffer} ) {
      $self->{lockFlag}++;
      $self->redraw();
      $self->{lockFlag}--;
    }
  }
  if ( $self->{buffer} ) {
    $self->writeBuf( 0, 0, $self->{size}{x}, $self->{size}{y}, $self->{buffer} );
  }
  else {
    $self->{clip} = $self->getClipRect();
    $self->redraw();
    $self->{clip} = $self->getExtent();
  }
  return;
} #/ sub draw

sub redraw {    # void ()
  my $self = shift;
  assert ( blessed $self );
  $self->drawSubViews( $self->first(), undef );
  return;
}

sub lock {    # void ()
  my $self = shift;
  assert ( blessed $self );
  $self->{lockFlag}++ 
    if $self->{buffer} || $self->{lockFlag};
  return;
}

sub unlock {    # void ()
  my $self = shift;
  assert ( blessed $self );
  $self->drawView() 
    if $self->{lockFlag} && --$self->{lockFlag} == 0;
  return;
}

sub resetCursor {    # void ()
  my $self = shift;
  assert ( blessed $self );
  $self->current()->resetCursor() 
    if $self->current();
  return;
}

sub endModal {    # void ($command)
  my ( $self, $command ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $command );
  if ( $self->{state} & sfModal ) {
    $self->{endState} = $command;
  }
  else {
    $self->SUPER::endModal( $command );
  }
  return;
} #/ sub endModal

sub eventError {    # void ($event)
  my ( $self, $event ) = @_;
  assert ( blessed $self );
  assert ( blessed $event );
  if ( $self->{owner} ) {
    $self->{owner}->eventError( $event );
  }
  return;
}

sub getHelpCtx {    # $int ()
  my $self = shift;
  assert ( blessed $self );
  my $h = hcNoContext;
  $h = $self->current()->getHelpCtx()
    if $self->current();
  $h = $self->SUPER::getHelpCtx()
    if $h == hcNoContext;
  return $h;
} #/ sub getHelpCtx

my $isInvalid = sub {    # $bool ($p, \$command)
  my ( $p, $command ) = @_;
  return !$p->valid( $$command );
};

sub valid {    # $bool ($command)
  my ( $self, $command ) = @_;
  if ( $command == cmReleasedFocus ) {
    return $self->current()->valid( $command )
      if $self->current()
      && ( $self->current()->{options} & ofValidate );
  }
  return !$self->firstThat( $isInvalid, \$command );
}

sub freeBuffer {    # void ()
  my $self = shift;
  assert ( blessed $self );
  if ( ( $self->{options} & ofBuffered ) && $self->{buffer} ) {
    $self->{buffer} = undef;
  }
  return;
}

sub getBuffer {    # void ()
  my $self = shift;
  assert ( blessed $self );
  $self->{buffer} = [ (0) x ( $self->{size}{x} * $self->{size}{y} * 2 ) ]
    if ( $self->{state} & sfExposed )
      && ( $self->{options} & ofBuffered )
      && !$self->{buffer};
  return;
} #/ sub getBuffer

$invalid = sub {    # $bool ($p, $command)
  ...
};

$focusView = sub {    # void ($p, $enable)
  my ( $self, $p, $enable ) = @_;
  $p->setState( sfFocused, $enable ) 
    if ( $self->{state} & sfFocused ) && $p;
  return;
};

$selectView = sub {    # void ($p, $enable)
  my ( $self, $p, $enable ) = @_;
  assert ( blessed $self );
  assert ( blessed $p );
  assert ( !defined $enable or !ref $enable );
  assert ( @_ == 3 );
  $p->setState( sfSelected, $enable )
    if $p;
  return;
}; #/ sub _selectView

$findNext = sub {
  my ( $self, $forwards ) = @_;
  my $p      = $self->current();
  my $result = undef;
  if ( $p ) {
    do {
      $p = $forwards ? $p->{next} : $p->prev();
    } while (
      !(
        ( ( $p->{state} & ( sfVisible | sfDisabled ) ) == sfVisible )
        && ( $p->{options} & ofSelectable )
      )
      && ( $p != $self->current() )
    );
    $result = $p 
      if $p != $self->current();
  } #/ if ( $p )
  return $result;
}; #/ sub findNext

__PACKAGE__->mk_accessors();

1
