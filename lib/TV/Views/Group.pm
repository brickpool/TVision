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
);

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
use TV::Views::View;

sub TGroup() { __PACKAGE__ }
sub name() { 'TGroup' }

use parent TView;

our $TheTopView;
our $ownerGroup;
{
  no warnings 'once';
  alias TGroup->{TheTopView} = $TheTopView;
  alias TGroup->{ownerGroup} = $ownerGroup;
}

alias my %REF = %TV::Views::View;

# private:
my (
  $invalid,
  $focusView,
  $selectView,
  $findNext,
);

sub new {    # $obj (%args)
  my ( $class, %args ) = @_;
  assert ( $class and !ref $class );
  assert ( ref $args{bounds} );
  my $self = $class->SUPER::new( %args );
  $self->{last}     = 0;
  $self->{phase}    = PH_FOCUSED;
  $self->{current}  = 0;
  $self->{buffer}   = undef;
  $self->{lockFlag} = 0;
  $self->{endState} = 0;
  $self->{options} |= OF_SELECTABLE | OF_BUFFERED;
  $self->{clip}      = $self->getExtent();
  $self->{eventMask} = 0xffff;
  return bless $self, $class;
} #/ sub new

sub DESTROY {    # void ()
  my $self = shift;
  assert ( blessed $self );
  $self->shutDown();
  return;
}

sub shutDown {    # void ()
  my $self = shift;
  assert ( blessed $self );
  my $p = $self->last();
  if ( $p ) {
    do {
      $p->hide();
      $p = $p->prev();
    } while ( $p && $p != $self->last() );

    do {
      my $T = $p->prev();
      $self->destroy( $p );
      $p = $T;
    } while ( $self->last() );
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
  return CM_CANCEL
    unless $p;

  my $saveOptions  = $p->{options};
  my $saveOwner    = $p->owner();
  my $saveTopView  = $TheTopView;
  my $saveCurrent  = $self->current();
  my $saveCommands = TCommandSet->new();
  $self->getCommands( $saveCommands );
  $TheTopView = $p;
  $p->{options} &= ~OF_SELECTABLE;
  $p->setState( SF_MODAL, !!1 );
  $self->setCurrent( $p, ENTER_SELECT );
  $self->insert( $p )
    unless $saveOwner;
  my $retval = $p->execute();
  $self->remove( $p )
    unless $saveOwner;
  $self->setCurrent( $saveCurrent, LEAVE_SELECT );
  $p->setState( SF_MODAL, !!0 );
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
      if ( $e->{what} != EV_NOTHING ) {
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

sub insertView {    # void ($self, $p, $Target)
  my ( $self, $p, $Target ) = @_;
  assert ( blessed $self );
  assert ( blessed $p );
  assert ( !defined $Target or blessed $Target );
  assert ( @_ == 3 );
  $p->owner( $self );
  if ( $Target ) {
    $Target = $Target->prev();
    $p->next( $Target->next() );
    $Target->next( $p );
  }
  else {
    if ( !$self->last() ) {
      $p->next( $p );
    }
    else {
      $p->next( $self->last()->next() );
      $self->last()->next( $p );
    }
    $self->last( $p );
  } #/ else [ if ( $Target ) ]
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
    if ( $saveState & SF_VISIBLE ) {
      $p->show();
    }
  } #/ if ( $p )
  return;
} #/ sub remove

# The following content was taken from the framework
# "A modern port of Turbo Vision 2.0", which is licensed under MIT licence.
#
# Copyright 2019-2021 by magiblot <magiblot@hotmail.com>
#
# I<tgrmv.cpp>
{
  sub removeView {    # void ($p)
    no warnings 'uninitialized';
    my ( $self, $p ) = @_;
    assert ( blessed $self );
    assert ( blessed $p );
    if ( $self->last() ) {
      my $s = $self->last();
      while ( 0+ $s->next() != $p ) {
        return
          if $s->next() == $self->last();
        $s = $s->next();
      }
      $s->next( $p->next );
      if ( $p == $self->last() ) {
        $self->last( $p == $p->next() ? undef : $s );
      }
    } #/ if ( $self->last() )
    return;
  } #/ sub removeView
}

sub resetCurrent {    # void ()
  my $self = shift;
  assert ( blessed $self );
  $self->setCurrent( $self->firstMatch( SF_VISIBLE, OF_SELECTABLE ),
    NORMAL_SELECT );
  return;
}

sub setCurrent {    # void ($p, $mode)
  no warnings 'uninitialized';
  my ( $self, $p, $mode ) = @_;
  assert ( blessed $self );
  assert ( !defined $p or blessed $p );
  assert ( looks_like_number $mode );
  return 
    if $self->current() == $p;

  $self->lock();
  $self->$focusView( $self->current(), 0 );
  $self->current()->setState( SF_SELECTED, 0 )
    if $mode != ENTER_SELECT 
    && $self->current();
  $p->setState( SF_SELECTED, 1 ) 
    if $mode != LEAVE_SELECT && $p;
  $p->setState( SF_FOCUSED,  1 ) 
    if ( $self->{state} & SF_FOCUSED ) && $p;
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
  no warnings 'uninitialized';
  my ( $self, $func, $args ) = @_;
  assert ( blessed $self );
  assert ( ref $func );
  assert ( @_ == 3 );
  my $temp = $self->last();
  return undef
    unless $temp;

  do {
    $temp = $temp->next();
    return $temp
      if $func->( $temp, $args );
  } while ( $temp != $self->last() );
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
  no warnings 'uninitialized';
  my ( $self, $func, $args ) = @_;
  assert ( blessed $self );
  assert ( ref $func );
  assert ( @_ == 3 );
  my $term = $self->last();
  my $temp = $term;
  return 
    unless $temp;

  my $next = $temp->next();
  do {
    $temp = $next;
    $next = $temp->next();
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

sub insertBefore {    # void ($self, $p, $Target)
  no warnings 'uninitialized';
  my ( $self, $p, $Target ) = @_;
  assert ( blessed $self );
  assert ( blessed $p );
  assert ( !defined $Target or blessed $Target );
  assert ( @_ == 3 );
  if ( $p && !$p->owner() && ( !$Target || $Target->owner() == $self ) ) {
    $p->{origin}{x} = ( $self->{size}{x} - $p->{size}{x} ) >> 1
      if $p->{options} & OF_CENTER_X;
    $p->{origin}{y} = ( $self->{size}{y} - $p->{size}{y} ) >> 1
      if $p->{options} & OF_CENTER_Y;
    my $saveState = $p->{state};
    $p->hide();
    $self->insertView( $p, $Target );
    $p->show()
      if $saveState & SF_VISIBLE;
    $p->setState( SF_ACTIVE, !!1 )
      if $saveState & SF_ACTIVE;
  } #/ if ( $p && !$p->owner(...))
} #/ sub insertBefore

sub current {    # $view|undef (|$view|undef)
  my $self = shift;
  assert ( blessed $self );
  if ( @_ ) {
    if ( defined( my $view = shift ) ) {
      assert ( blessed $view );
      my $id = 0+ $view;
      weaken( $REF{$id} = $view )
        if !$REF{$id};
      $self->{current} = $id;
    }
    elsif ( my $id = $self->{current} ) {
      delete( $REF{$id} )
        if $REF{$id};
      $self->{current} = 0;
    }
  } #/ if ( @_ )
  return $REF{ $self->{current} };
} #/ sub current

sub at {    # $view|undef ($index)
  my ( $self, $index ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $index );
  my $temp = $self->last();
  while ( $index-- > 0 ) {
    $temp = $temp->next();
  }
  return $temp;
} #/ sub at

sub firstMatch {    # $view|undef ($aState, $aOptions)
  no warnings 'uninitialized';
  my ( $self, $aState, $aOptions ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $aState );
  assert ( looks_like_number $aOptions );
  return undef 
    unless $self->last();

  my $temp = $self->last();
  while ( 1 ) {
    return $temp
      if ( $temp->{state} & $aState ) == $aState
      && ( $temp->{options} & $aOptions ) == $aOptions;
    $temp = $temp->next();
    return undef 
      if $temp == $self->last();
  }
} #/ sub firstMatch

sub indexOf {    # $int ($p)
  no warnings 'uninitialized';
  my ( $self, $p ) = @_;
  assert ( blessed $self );
  assert ( blessed $p );
  return 0 
    unless $self->last();

  my $index = 0;
  my $temp  = $self->last();
  do {
    $index++;
    $temp = $temp->next();
  } while ( $temp != $p && $temp != $self->last() );
  return $temp == $p ? $index : 0;
} #/ sub indexOf

sub matches {    # $bool ($p)
  ...
}

sub first {    # $view|undef ()
  my $self = shift;
  assert ( blessed $self );
  return $self->last() ? $self->last()->next() : undef;
}

my $doExpose = sub {    # void ($p, \$enable)
  my ( $p, $enable ) = @_;
  $p->setState( SF_EXPOSED, $$enable )
    if $p->state & SF_VISIBLE;
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

  if ( $aState & ( SF_ACTIVE | SF_DRAGGING ) ) {
    $self->lock();
    $self->forEach( $doSetState, $sb );
    $self->unlock();
  }

  if ( $aState & SF_FOCUSED ) {
    $self->current()->setState( SF_FOCUSED, $enable ) 
      if $self->current();
  }

  if ( $aState & SF_EXPOSED ) {
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
    if ( $p->{state} & SF_DISABLED )
    && ( $s->{event}{what} & ( POSITIONAL_EVENTS | FOCUSED_EVENTS ) );

  SWITCH: for ( $s->{grp}{phase} ) {
    $_ == PH_PRE_PROCESS and do {
      return
        unless $p->{options} & OF_PRE_PROCESS;
      last;
    };
    $_ == PH_POST_PROCESS and do {
      return
        unless $p->{options} & OF_POST_PROCESS;
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

sub handleEvent { # void ($event)
  my ( $self, $event ) = @_;
  assert ( blessed $self );
  assert ( blessed $event );
  $self->SUPER::handleEvent( $event );

  my $hs = { 
    event => $event, 
    grp => $self
  };

  if ( $event->{what} & FOCUSED_EVENTS ) {
    $self->{phase} = PH_PRE_PROCESS;
    $self->forEach( $doHandleEvent, $hs );

    $self->{phase} = PH_FOCUSED;
    $doHandleEvent->( $self->current(), $hs );

    $self->{phase} = PH_POST_PROCESS;
    $self->forEach( $doHandleEvent, $hs );
  } #/ if ( $event->{what} & ...)
  else {
    $self->{phase} = PH_FOCUSED;
    if ( $event->{what} & POSITIONAL_EVENTS ) {
      # get pointer to topmost view holding mouse
      my $p = $self->firstThat( $hasMouse, $event );
      if ( $p ) {
        # we have a view; send event to it
        $doHandleEvent->( $p, $hs );
      }
      elsif ( $event->{what} == EV_MOUSE_DOWN ) {
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

sub drawSubViews {    # void ($p, $bottom)
  no warnings 'uninitialized';
  my ( $self, $p, $bottom ) = @_;
  assert ( blessed $self );
  assert ( blessed $p );
  assert ( blessed $bottom );
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
  if ( $self->last() ) {
    my $v = $self->last();
    do {
      $v->getData( alias [ @$rec[ $i .. $#$rec ] ] );
      $i += $v->dataSize();
      $v = $v->prev();
    } while ( $v != $self->last() );
  }
  return;
} #/ sub getData

sub setData {    # void (\@rec)
  my ( $self, $rec ) = @_;
  assert ( blessed $self );
  assert ( ref $rec );
  my $i = 0;
  if ( $self->last() ) {
    my $v = $self->last();
    do {
      $v->setData( alias [ @$rec[ $i .. $#$rec ] ] );
      $i += $v->dataSize();
      $v = $v->prev();
    } while ( $v != $self->last() );
  }
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
  if ( $self->{state} & SF_MODAL ) {
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
  if ( $self->owner() ) {
    $self->owner()->eventError( $event );
  }
  return;
}

sub getHelpCtx {    # $int ()
  my $self = shift;
  assert ( blessed $self );
  my $h = HC_NO_CONTEXT;
  $h = $self->current()->getHelpCtx()
    if $self->current();
  $h = $self->SUPER::getHelpCtx()
    if $h == HC_NO_CONTEXT;
  return $h;
} #/ sub getHelpCtx

my $isInvalid = sub {    # $bool ($p, \$command)
  my ( $p, $command ) = @_;
  return !$p->valid( $$command );
};

sub valid {    # $bool ($command)
  my ( $self, $command ) = @_;
  if ( $command == CM_RELEASED_FOCUS ) {
    return $self->current()->valid( $command )
      if $self->current()
      && ( $self->current()->{options} & OF_VALIDATE );
  }
  return !$self->firstThat( $isInvalid, \$command );
}

sub freeBuffer {    # void ()
  my $self = shift;
  assert ( blessed $self );
  if ( ( $self->{options} & OF_BUFFERED ) && $self->{buffer} ) {
    $self->{buffer} = undef;
  }
  return;
}

sub getBuffer {    # void ()
  my $self = shift;
  assert ( blessed $self );
  $self->{buffer} = [ (0) x ( $self->{size}{x} * $self->{size}{y} * 2 ) ]
    if ( $self->{state} & SF_EXPOSED )
      && ( $self->{options} & OF_BUFFERED )
      && !$self->{buffer};
  return;
} #/ sub getBuffer

sub last {    # $view (|$view|undef)
  my $self = shift;
  assert ( blessed $self );
  if ( @_ ) {
    if ( defined( my $view = shift ) ) {
      assert ( blessed $view );
      my $id = 0+ $view;
      weaken( $REF{$id} = $view )
        if !$REF{$id};
      $self->{last} = $id;
    }
    elsif ( my $id = $self->{last} ) {
      delete( $REF{$id} )
        if $REF{$id};
      $self->{last} = 0;
    }
  } #/ if ( @_ )
  return $REF{ $self->{last} };
} #/ sub last

$invalid = sub {    # $bool ($p, $command)
  ...
};

$focusView = sub {    # void ($p, $enable)
  my ( $self, $p, $enable ) = @_;
  $p->setState( SF_FOCUSED, $enable ) 
    if ( $self->{state} & SF_FOCUSED ) && $p;
  return;
};

$selectView = sub {    # void ($p, $enable)
  my ( $self, $p, $enable ) = @_;
  assert ( blessed $self );
  assert ( blessed $p );
  assert ( !defined $enable or !ref $enable );
  assert ( @_ == 3 );
  $p->setState( SF_SELECTED, $enable )
    if $p;
  return;
}; #/ sub _selectView

$findNext = sub {
  my ( $self, $forwards ) = @_;
  my $p      = $self->current();
  my $result = undef;
  if ( $p ) {
    do {
      $p = $forwards ? $p->next() : $p->prev();
    } while (
      !(
        ( ( $p->{state} & ( SF_VISIBLE | SF_DISABLED ) ) == SF_VISIBLE )
        && ( $p->{options} & OF_SELECTABLE )
      )
      && ( $p != $self->current() )
    );
    $result = $p 
      if $p != $self->current();
  } #/ if ( $p )
  return $result;
}; #/ sub findNext

1
