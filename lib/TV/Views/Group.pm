package TV::Views::Group;
# ABSTRACT: Base class for all group components in Turbo Vision

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TGroup
  new_TGroup
);

use Devel::StrictMode;
use Scalar::Util qw(
  weaken
  isweak
);
use TV::toolkit;
use TV::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TV::Objects::Point;
use TV::Objects::Rect;
use TV::Drivers::Const qw(
  :evXXXX
);
use TV::Drivers::Event;
use TV::Views::Const qw(
  :phaseType
  :selectMode
  :cmXXXX
  :evXXXX
  :hcXXXX
  :ofXXXX
  :sfXXXX
);
use TV::Views::CommandSet;
use TV::Views::View;

sub TGroup() { __PACKAGE__ }
sub name() { 'TGroup' }
sub new_TGroup { __PACKAGE__->from(@_) }

extends TView;

# declare global variables
our $TheTopView;
our $ownerGroup;

# public attributes
has current   => ( is => 'bare' );
has last      => ( is => 'ro' );
has clip      => ( is => 'rw' );
has phase     => ( is => 'ro', default => phFocused );
has buffer    => ( is => 'ro' );
has lockFlag  => ( is => 'rw', default => 0 );
has endState  => ( is => 'rw', default => 0 );

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

my $weaken = sub {
  # warn join(',' => caller()), "\n";
  &$unlock_value( $_[0] ) if STRICT;
  weaken $_[0];
  &$lock_value( $_[0] ) if STRICT;
};

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{eventMask} = 0xffff;
  $self->{options} |= ofSelectable | ofBuffered;
  $self->{clip} = $self->getExtent();
  weaken( $self->{current} ) if $self->{current};
  &$lock_value( $self->{current} ) if STRICT;
  return;
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Bool $in_global_destruction );
  &$unlock_value( $self->{current} ) if STRICT;
  $self->shutDown() unless $in_global_destruction;
  return;
}

sub shutDown {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $p = $self->{last};
  if ( $p ) {
    do {
      $p->hide();
      $p = $p->prev();
    } while ( $p && $p != $self->{last} );

    while ( $p && $self->{last} ) {
      my $T = $p->prev();
      $self->destroy( $p );
      $p = $T; 
    }
  } #/ if ( $p )
  $self->freeBuffer();
  $self->current( undef );
  $self->SUPER::shutDown();
  return;
} #/ sub shutDown

sub execView {    # $int ($p|undef)
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Object]],
  );
  my ( $self, $p ) = $sig->( @_ );
  alias: for $p ( $_[1] ) {
  return cmCancel
    unless $p;

  my $saveOptions = $p->{options};
  my $saveOwner = $p->{owner};
  my $saveTopView = $TheTopView;
  my $saveCurrent = $self->{current};
  my $saveCommands = TCommandSet->new();
  $self->getCommands( $saveCommands );
  weaken( $TheTopView = $p );
  $p->{options} &= ~ofSelectable;
  $p->setState( sfModal, true );
  $self->setCurrent( $p, enterSelect );
  $self->insert( $p )
    unless $saveOwner;
  my $retval = $p->execute();
  $self->remove( $p )
    unless $saveOwner;
  $self->setCurrent( $saveCurrent, leaveSelect );
  $p->setState( sfModal, false );
  $p->{options} = $saveOptions;
  weaken( $TheTopView = $saveTopView );
  $self->setCommands( $saveCommands );
  return $retval;
  } #/ alias:
} #/ sub execView

sub execute {    # $int ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
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
}

my $doAwaken = sub {    # void ($v, $p)
  assert ( @_ == 2 );
  assert ( is_Object $_[0] );
  $_[0]->awaken();
  return;
};

sub awaken {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->forEach( $doAwaken );
  return;
}

sub insertView {    # void ($p, $Target|undef)
  state $sig = signature(
    method => Object,
    pos    => [Object, Maybe[Object]],
  );
  my ( $self, $p, $Target ) = $sig->( @_ );
  $p->owner( $self );
  if ( $Target ) {
    assert ( $Target->{owner} == $self );
    assert ( $self->{last} );

    # Check if the cycle needs to be weakened again.
    my $weak_cycle = $self->{last} == $Target;

    # Insert new element (as originally)
    $Target = $Target->prev();
    $p->next( $Target->{next} );
    $Target->next( $p );

    q/*
      warn "\t\$Target => $Target\n";
      warn "\t\$p => $p\n";
      my $s = $self->{last};
      while ( $s->{next} && $s->{next} != $self->{last} ) {
        warn "\t\t\$" . $s . "->{next} => \\%" . $s->{next} . "\n";
        $s = $s->{next};
      }
      warn "\t\t\$" . $s . "->{next} => " . ( $s->{next} || 'undef' ) . "\n";
    */ if 0;

    # Set new weak reference if necessary
    &$weaken( $self->{last}->prev()->{next} ) if $weak_cycle;
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

    # Set new weak reference
    &$weaken( $p->prev()->{next} );
  } #/ else [ if ( $Target ) ]
  q/*
    require Devel::Cycle; 
    warn $_ if local $_ = Devel::Cycle::find_cycle( $p );
  */ if 0;
  return;
} #/ sub insertView

sub remove {    # void ($p|undef)
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Object]],
  );
  my ( $self, $p ) = $sig->( @_ );
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
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $p ) = $sig->( @_ );
  if ( $self->{last} ) {
    no warnings qw( uninitialized numeric );
    my $s = $self->{last};

    # Check if the cycle needs to be weakened again.
    my $weak_cycle = $s == $p || $s == $p->{next};

    while ( $s->{next} != $p ) {
      return
        if $s->{next} == $self->{last};
      $s = $s->{next};
    }
    $s->next( $p->{next} );

    # Weaken the {next} field of the removed entry.
    &$weaken( $p->{next} ) unless isweak $p->{next};

    if ( $p == $self->{last} ) {
      if ( $p == $p->{next} ) {
        $self->{last} = undef;
        return;
      }
      $self->{last} = $s;
    } 

    # Set new weak reference if necessary
    &$weaken( $self->{last}->prev()->{next} ) if $weak_cycle;
    q/*
      require Devel::Cycle; 
      warn $_ if local $_ = Devel::Cycle::find_cycle( $p );
    */ if 0;
  } #/ if ( $self->{last} )
  return;
} #/ sub removeView

sub resetCurrent {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->setCurrent( $self->firstMatch( sfVisible, ofSelectable ),
    normalSelect );
  return;
}

sub setCurrent {    # void ($p|undef, $mode)
  no warnings qw( uninitialized numeric );
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Object], PositiveOrZeroInt],
  );
  my ( $self, $p, $mode ) = $sig->( @_ );
  return 
    if $self->{current} == $p;

  $self->lock();
  $self->$focusView( $self->{current}, false );
  $self->{current}->setState( sfSelected, false )
    if $mode != enterSelect 
    && $self->{current};
  $p->setState( sfSelected, true ) 
    if $mode != leaveSelect && $p;
  $p->setState( sfFocused, true ) 
    if ( $self->{state} & sfFocused ) && $p;
  $self->current( $p );
  $self->unlock();
  return;
} #/ sub setCurrent

sub selectNext {    # void ($forwards)
  state $sig = signature(
    method => Object,
    pos    => [Bool],
  );
  my ( $self, $forwards ) = $sig->( @_ );
  if ( $self->{current} ) {
    my $p = $self->$findNext( $forwards );
    $p->select() if $p;
  }
  return;
} #/ sub selectNext

sub firstThat {    # $view|undef (\&Test, @args)
  state $sig = signature(
    method => Object,
    pos    => [
      CodeRef, 
      ArrayRef, { slurpy => 1 }
    ],
  );
  my ( $self, $func, $args ) = $sig->( @_ );
  my $temp = $self->{last};
  return undef
    unless $temp;

  no warnings qw( uninitialized numeric );
  do {
    $temp = $temp->{next};
    return $temp
      if $func->( $temp, @$args );
  } while ( $temp != $self->{last} );
  return undef;
} #/ sub firstThat

sub focusNext {    # $bool ($forwards)
  state $sig = signature(
    method => Object,
    pos    => [Bool],
  );
  my ( $self, $forwards ) = $sig->( @_ );
  my $p = $self->$findNext( $forwards );
  return $p ? $p->focus() : true;
}

sub forEach {    # void (\&action, @args)
  state $sig = signature(
    method => Object,
    pos    => [
      CodeRef, 
      ArrayRef, { slurpy => 1 }
    ],
  );
  my ( $self, $func, $args ) = $sig->( @_ );
  my $term = $self->{last};
  my $temp = $self->{last};
  return 
    unless $temp;

  no warnings qw( uninitialized numeric );
  my $next = $temp->{next};
  do {
    $temp = $next;
    $next = $temp->{next};
    $func->( $temp, @$args );
  } while ( $temp != $term );
  return;
} #/ sub forEach

sub insert {    # void ($p|undef)
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Object]],
  );
  my ( $self, $p ) = $sig->( @_ );
  $self->insertBefore( $p, $self->first() );
  return;
}

sub insertBefore {    # void ($p, $Target|undef)
  no warnings qw( uninitialized numeric );
  state $sig = signature(
    method => Object,
    pos    => [Object, Maybe[Object]],
  );
  my ( $self, $p, $Target ) = $sig->( @_ );
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
    $p->setState( sfActive, true )
      if $saveState & sfActive;
  } #/ if ( $p && !$p->owner(...))
} #/ sub insertBefore

sub current {    # $view|undef (|$view|undef)
  state $sig = signature(
    method => Object,
    pos    => [
      Maybe[Object], { optional => 1 },
    ],
  );
  my ( $self, $view ) = $sig->( @_ );
  goto SET if @_ > 1;
  GET: {
    return $self->{current};
  }
  SET: {
    &$unlock_value( $self->{current} ) if STRICT;
    weaken $self->{current}
      if $self->{current} = $view;
    &$lock_value( $self->{current} ) if STRICT;
    return;
  }
}

sub at {    # $view|undef ($index)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $index ) = $sig->( @_ );
  my $temp = $self->{last};
  while ( $index-- > 0 ) {
    $temp = $temp->{next};
  }
  return $temp;
} #/ sub at

sub firstMatch {    # $view|undef ($aState, $aOptions)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, PositiveOrZeroInt],
  );
  my ( $self, $aState, $aOptions ) = $sig->( @_ );
  return undef 
    unless $self->{last};

  no warnings qw( uninitialized numeric );
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
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $p ) = $sig->( @_ );
  return 0 
    unless $self->{last};

  no warnings qw( uninitialized numeric );
  my $index = 0;
  my $temp  = $self->{last};
  do {
    $index++;
    $temp = $temp->{next};
  } while ( $temp != $p && $temp != $self->{last} );
  return $temp == $p ? $index : 0;
} #/ sub indexOf

sub matches {    # $bool ($p)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  $sig->( @_ );
  ...
}

sub first {    # $view|undef ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return $self->{last} ? $self->{last}{next} : undef;
}

my $doExpose = sub {    # void ($p, \$enable)
  my ( $p, $enable ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $p );
  assert ( is_ScalarRef $enable );
  $p->setState( sfExposed, $$enable )
    if $p->state & sfVisible;
  return;
};

my $doSetState = sub {    # void ($p, \%b)
  my ( $p, $b ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $p );
  assert ( is_HashLike $b );
  $p->setState( $b->{st}, $b->{en} );
  return;
};

sub setState {    # void ($aState, $enable)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Bool],
  );
  my ( $self, $aState, $enable ) = $sig->( @_ );
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
    $self->{current}->setState( sfFocused, $enable ) 
      if $self->{current};
  }

  if ( $aState & sfExposed ) {
    $self->forEach( $doExpose, \$enable );
    $self->freeBuffer() 
      unless $enable;
  }
  return;
} #/ sub setState

my $doHandleEvent = sub {    # void ($p|undef, \%s)
  my ( $p, $s ) = @_;
  assert ( @_ == 2 );
  assert ( !defined $p or is_Object $p );
  assert ( is_HashLike $s );
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
  }
  $p->handleEvent( $s->{event} )
    if $s->{event}{what} & $p->{eventMask};
  return;
};

my $hasMouse = sub {    # $bool ($p, $s)
  my ( $p, $s ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $p );
  assert ( is_HashLike $s );
  return $p->containsMouse( $s );
};

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  $self->SUPER::handleEvent( $event );

  my $hs = { 
    event => $event, 
    grp => $self
  };

  if ( $event->{what} & focusedEvents ) {
    $self->{phase} = phPreProcess;
    $self->forEach( $doHandleEvent, $hs );

    $self->{phase} = phFocused;
    &$doHandleEvent( $self->{current}, $hs );

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
        &$doHandleEvent( $p, $hs );
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
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Object], Maybe[Object]],
  );
  my ( $self, $p, $bottom ) = $sig->( @_ );
  no warnings qw( uninitialized numeric );
  while ( $p != $bottom ) {
    $p->drawView();
    $p = $p->nextView();
  }
  return;
}

my $doCalcChange = sub {    # void ($p, $d)
  my ( $p, $d ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $p );
  assert ( is_Object $d );
  my $r = TRect->new();
  $p->calcBounds( $r, $d );
  $p->changeBounds( $r );
  return;
};

sub changeBounds {    # void ($self, $bounds)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $bounds ) = $sig->( @_ );
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

my $addSubviewDataSize = sub {    # void ($p, \$T)
  my ( $p, $T ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $p );
  assert ( is_ScalarRef $T );
  $$T += $p->dataSize();
};

sub dataSize {    # $int ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $T = 0;
  $self->forEach( $addSubviewDataSize, \$T );
  return $T;
}

sub getData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  my ( $self, $rec ) = $sig->( @_ );
  my $i = 0;
  if ( $self->{last} ) {
    my $v = $self->{last};
    do {
      $v->getData( sub { \@_ }->( @$rec[ $i .. $#$rec ] ) );
      $i += $v->dataSize();
      $v = $v->prev();
    } while ( $v != $self->{last} );
  }
  return;
} #/ sub getData

sub setData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  my ( $self, $rec ) = $sig->( @_ );
  my $i = 0;
  if ( $self->{last} ) {
    my $v = $self->{last};
    do {
      $v->setData( sub { \@_ }->( @$rec[ $i .. $#$rec ] ) );
      $i += $v->dataSize();
      $v = $v->prev();
    } while ( $v != $self->{last} );
  }
  return;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
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
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->drawSubViews( $self->first(), undef );
  return;
}

sub lock {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->{lockFlag}++ 
    if $self->{buffer} || $self->{lockFlag};
  return;
}

sub unlock {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->drawView() 
    if $self->{lockFlag} && --$self->{lockFlag} == 0;
  return;
}

sub resetCursor {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->{current}->resetCursor() 
    if $self->{current};
  return;
}

sub endModal {    # void ($command)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $command ) = $sig->( @_ );
  if ( $self->{state} & sfModal ) {
    $self->{endState} = $command;
  }
  else {
    $self->SUPER::endModal( $command );
  }
  return;
}

sub eventError {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  if ( $self->{owner} ) {
    $self->{owner}->eventError( $event );
  }
  return;
}

sub getHelpCtx {    # $int ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $h = hcNoContext;
  $h = $self->{current}->getHelpCtx()
    if $self->{current};
  $h = $self->SUPER::getHelpCtx()
    if $h == hcNoContext;
  return $h;
}

my $isInvalid = sub {    # $bool ($p, \$command)
  my ( $p, $command ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $p );
  assert ( is_ScalarRef $command );
  return !$p->valid( $$command );
};

sub valid {    # $bool ($command)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $command ) = $sig->( @_ );
  if ( $command == cmReleasedFocus ) {
    if ( $self->{current}
      && ( $self->{current}{options} & ofValidate )
    ) {
      return $self->{current}->valid( $command );
    }
    else {
      return true;
    }
  }
  return !$self->firstThat( $isInvalid, \$command );
}

sub freeBuffer {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  if ( ( $self->{options} & ofBuffered ) && $self->{buffer} ) {
    $self->{buffer} = undef;
  }
  return;
}

sub getBuffer {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->{buffer} = [ (0) x ( $self->{size}{x} * $self->{size}{y} * 2 ) ]
    if ( $self->{state} & sfExposed )
      && ( $self->{options} & ofBuffered )
      && !$self->{buffer};
  return;
}

$focusView = sub {    # void ($p|undef, $enable)
  my ( $self, $p, $enable ) = @_;
  assert ( @_ == 3 );
  assert ( !defined $p or is_Object $p );
  assert ( is_Bool $enable );
  $p->setState( sfFocused, $enable ) 
    if ( $self->{state} & sfFocused ) && $p;
  return;
};

$selectView = sub {    # void ($p, $enable)
  my ( $self, $p, $enable ) = @_;
  assert ( @_ == 3 );
  assert ( is_Object $p );
  assert ( is_Bool $enable );
  $p->setState( sfSelected, $enable )
    if $p;
  return;
};

$findNext = sub {
  my ( $self, $forwards ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Bool $forwards );
  my $p      = $self->{current};
  my $result = undef;
  if ( $p ) {
    do {
      $p = $forwards ? $p->{next} : $p->prev();
    } while (
      !(
        ( ( $p->{state} & ( sfVisible | sfDisabled ) ) == sfVisible )
        && ( $p->{options} & ofSelectable )
      )
      && ( $p != $self->{current} )
    );
    $result = $p 
      if $p != $self->{current};
  } #/ if ( $p )
  return $result;
};

1

__END__

=pod

=head1 NAME

TV::Views::Group - a base class for all group components in Turbo Vision.

=head1 SYNOPSIS

  use TV::Views;

  my $group = TGroup->new(bounds => $bounds);
  $group->insert($view);
  $group->remove($view);

=head1 DESCRIPTION

The C<TGroup> class is the base class for all group components in Turbo Vision.
It provides methods for managing child views, event handling, and drawing the
group and its children.

=head1 ATTRIBUTES

=over

=item buffer

This attribute is typically used to store temporary data or intermediate results 
during processing. (ArrayRef)

=item clip

The clipping rectangle of the group, represented by a C<TRect>. It defines the 
area within which drawing operations are allowed. (TRect)

=item current

This attribute usually refers to the currently active or selected item within a 
group or list. (TView)

=item endState

This attribute represents the final state of an object or process after it has 
completed its operation. (Int)

=item last

This attribute often points to the last item in a list or sequence. (TView)

=item lockFlag

This attribute is used to indicate whether a resource or process is locked, 
preventing other operations from modifying it. (Bool)

=item phase

This attribute represents the current phase or stage of a process or operation. 
(Int)

=back

=head1 METHODS

=head2 new

  my $group = TGroup->new(bounds => $bounds);

Initializes an instance of C<TGroup> with the specified bounds.

=over

=item bounds

The bounds of the view (TRect).

=back

=head2 DESTROY

  $self->DESTROY();

DESTROY first hides the group and then calls destroy for each view's.

=head2 at

 my $view | undef = at($index);

Returns the view at the specified index.

=head2 awaken

  $self->awaken();

Awakens the group, making it active.

=head2 changeBounds

  $self->changeBounds($self, $bounds);

Changes the bounds of the group.

=head2 current

  my $view | undef = current( | $view | undef);

Returns the current view or sets it to the specified view.

=head2 dataSize

  my $int = dataSize();

Returns the size of the data.

=head2 draw

  $self->draw();

Draws the group and its children on the screen.

=head2 drawSubViews

  $self->drawSubViews($p | undef, $bottom | undef);

Draws the subviews of the group.

=head2 endModal

  $self->endModal($command);

Ends a modal state with the specified command.

=head2 eventError

  $self->eventError($event);

Handles an error event.

=head2 execView

  my $int = $self->execView();

Executes the view and returns a status code.

=head2 execute

  my $int = $self->execute();

Executes the group and returns a status code.

=head2 first

  my $view | undef = $self->first();

Returns the first view in the group.

=head2 firstMatch

  my $view | undef = $self->firstMatch($aState, $aOptions);

Returns the first view that matches the specified state and options.

=head2 firstThat

  my $view | undef = $self->firstThat(\&Test, @args);

Returns the first view that satisfies the specified function.

=head2 focusNext

  my $bool = $self->focusNext($forwards);

Moves the focus to the next view.

=head2 forEach

  $self->forEach(\&action, @args);

Applies the specified function to each view in the group.

=head2 freeBuffer

  $self->freeBuffer();

Frees the buffer used by the group.

=head2 getBuffer

  $self->getBuffer();

Gets the buffer used by the group.

=head2 getData

  $self->getData(\@rec);

Returns the data of the group.

=head2 getHelpCtx

 my $int = $self->getHelpCtx();

Returns the help context of the group.

=head2 handleEvent

  $self->handleEvent($event);

Handles an event sent to the group.

=head2 indexOf

  my $int = $self->indexOf($p);

Returns the index of the specified view.

=head2 insert

  $self->insert($p);

Inserts a view into the group.

=head2 insertBefore

  $self->insertBefore($p, $Target | undef);

Inserts a view before the specified target.

=head2 insertView

  $self->insertView($p, $Target | undef);

Inserts a view into the group.

=head2 lock

  $self->lock();

Locks the group to prevent updates.

=head2 matches

 my $bool = $self->matches($p);

Checks if the group matches the specified criteria.

=head2 redraw

  $self->redraw();

Redraws the group.

=head2 remove

  $self->remove($p|undef);

Removes a view from the group.

=head2 removeView

  $self->removeView($p);

Removes a view from the group.

=head2 resetCurrent

  $self->resetCurrent();

Resets the current view.

=head2 resetCursor

  $self->resetCursor();

Resets the cursor position.

=head2 selectNext

  $self->selectNext($forwards);

Selects the next view.

=head2 setCurrent

  $self->setCurrent($p, $mode);

Sets the current view to the specified view.

=head2 setData

  $self->setData(\@rec);

Sets the data of the group to the specified values.

=head2 setState

  $self->setState($aState, $enable);

Sets the state of the group to the specified value.

=head2 shutDown

  $self->shutDown();

Shuts down the group.

=head2 unlock

  $self->unlock();

Unlocks the group to allow updates.

=head2 valid

 my $bool = $self->valid($command);

Checks if the group is in a valid state.

=head1 AUTHORS

=over

=item Turbo Vision Development Team

=item J. Schneider <brickpool@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution). This documentation is provided under the same terms 
as the Turbo Vision library itself.

=cut
