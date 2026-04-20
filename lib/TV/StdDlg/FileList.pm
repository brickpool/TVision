package TV::StdDlg::FileList;
# ABSTRACT: TListBox subclass for file lists in TFileList

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT = qw(
  TFileList
  new_TFileList
);

use PerlX::Assert::PP;
use TV::toolkit;
use TV::toolkit::Params qw( signature );
use TV::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TV::Const qw( EOS );
use TV::Drivers::Const qw(
  evBroadcast
  kbShift
);
use TV::MsgBox::Const qw(
  mfOKButton
  mfWarning
);
use TV::MsgBox::MsgBoxText qw( messageBox );
use TV::StdDlg::Const qw(
  cmFileDoubleClicked
  cmFileFocused
  :FA_
);
use TV::StdDlg::FileCollection;
use TV::StdDlg::SortedListBox;
use TV::StdDlg::Dir qw(
  findfirst
  findnext
  fnmerge
  fnsplit
);
use TV::StdDlg::Util qw( fexpand );
use TV::Views::Util qw( message );

sub TFileList() { __PACKAGE__ }
sub name() { 'TFileList' }
sub new_TFileList { __PACKAGE__->from( @_ ) }

extends TSortedListBox;

# declare global variables
our $tooManyFiles = "Too many files.";

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      bounds     => Object,
      vScrollBar => Maybe[Object], { alias => 'aScrollBar' },
    ],
    caller_level => +1,
  );
  my ( $class, $args1 ) = $sig->( @_ );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  my $args2 = $class->SUPER::BUILDARGS(
    bounds     => $args1->{bounds},
    numCols    => 2,
    vScrollBar => $args1->{vScrollBar},
  );
  return { %$args1, %$args2 };
}

sub from {    # $obj ($bounds, $aVScrollBar|undef)
  state $sig = signature(
    method => 1,
    pos    => [Object, Maybe[Object]],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], vScrollBar => $args[2] );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  alias: for my $list ( $self->{items} ) {
  $self->destroy( $list );
  return;
  } #/ alias: 
}

sub focusItem {    # void ($item)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $item ) = $sig->( @_ );
  $self->SUPER::focusItem( $item );
  message( $self->{owner}, evBroadcast, cmFileFocused, 
    $self->list->at( $item ) );
  return;
}

sub selectItem {    # void ($item)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $item ) = $sig->( @_ );
  message( $self->{owner}, evBroadcast, cmFileDoubleClicked, 
    $self->list()->at( $item ) );
  return;
}

sub getText {    # void (\$dest, $item, $maxChars)
  state $sig = signature(
    method => Object,
    pos    => [ScalarRef, Int, Int],
  );
  my ( $self, $dest, $item, $maxChars ) = $sig->( @_ );
  my $f = $self->list()->at( $item );
  assert ( is_Object $f );
  $$dest = substr( $f->name(), 0, $maxChars );
  $$dest .= "\\"
    if f->attr & FA_DIREC;
  return;
}

sub newList {    # void ($aList)
  goto &TV::StdDlg::SortedListBox::newList;
}

sub readDirectory { # void (|$dir, $wildCard)
  state $sig = signature(
    method => Object,
    pos => [
      Str, 
      Str, { default => '' },
    ],
  );
  my ( $self, @args ) = $sig->( @_ );
  my $aWildCard = join '' => @args;

  my $s = ffblk->new();
  my $path = $aWildCard;
  fexpand( $path );
  my ( $drive, $dir, $file, $ext );
  fnsplit( $path, $drive, $dir, $file, $ext );

  my $fileList = TFileCollection->new( limit => 5, delta => 5 );

  my $res = findfirst( $aWildCard, $s, FA_RDONLY | FA_ARCH );
  my $p = 1;    # sentinel: true at start
  while ( $p && $res == 0 ) {
    if ( ( $s->ff_attrib() & FA_DIREC ) == 0 ) {
      $p = DirSearchRec->new();
      if ( $p ) {
        $p->readFf_blk( $s );
        $fileList->insert( $p );
      }
    }
    $res = findnext( $s );
  }

  fnmerge( $path, $drive, $dir, "*", ".*" );

  $res = findfirst( $path, $s, FA_DIREC );
  while ( $p && $res == 0 ) {
    if ( ( $s->ff_attrib() & FA_DIREC )
      && substr( $s->ff_name, 0, 1 ) ne '.'
    ) {
      $p = DirSearchRec->new();
      if ( $p ) {
        $p->readFf_blk( $s );
        $fileList->insert( $p );
      }
    }
    $res = findnext( $s );
  }

  if ( length $dir > 1 ) {
    $p = DirSearchRec->new();
    if ( $p ) {
      if ( findfirst( $path, $s, FA_DIREC ) == 0
        && findnext( $s ) == 0
        && $s->ff_name eq '..'
      ) {
        $p->readFf_blk( $s );
      }
      else {
        $p->name( '..' );
        $p->size( 0 );
        $p->time( 0x210000 );
        $p->attr( FA_DIREC );
      }
      $fileList->insert( $p );
    }
  } #/ if ( length( $dir ) > ...)

  unless ( $p ) {
    messageBox( $tooManyFiles, mfOKButton | mfWarning );
  }
  $self->newList( $fileList );
  if ( $self->list()->getCount() > 0 ) {
    message( $self->{owner}, evBroadcast, cmFileFocused, 
      $self->list()->at( 0 ) );
  }
  else {
    state $noFile = DirSearchRec->new();
    message( $self->{owner}, evBroadcast, cmFileFocused, $noFile );
  }
  return;
}

sub dataSize {    # $size ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  $sig->( @_ );
  return 0;
}

sub getData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  $sig->( @_ );
  return;
}

sub setData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  $sig->( @_ );
  return;
}

sub list {    # $fileCollection ()
  goto &TV::StdDlg::SortedListBox::list;
}

sub getKey {    # $key ($s)
  state $sig = signature(
    method => Object,
    pos    => [Str],
  );
  my ( $self, $s ) = $sig->( @_ );
  state $sR = TSearchRec->new();
  if ( ( $self->{shiftState} & kbShift ) || $s eq '.' ) {
    $sR->attr( FA_DIREC );
  }
  else {
    $sR->attr( 0 );
  }
  $sR->name( uc $s );
  return $sR;
}

{
  package DirSearchRec;
  use PerlX::Assert::PP;
  use Scalar::Util qw( blessed );
  use base 'TSearchRec';
  sub readFf_blk { # void ($f)
    my ( $self, $f ) = @_;
    assert ( @_ == 2 );
    assert ( blessed $self );
    assert ( blessed $f );
    $self->attr( $f->ff_attrib );
    $self->time( ( $f->ff_fdate() << 16 ) | $f->ff_ftime );
    $self->size( $f->ff_fsize );
    $self->name( $f->ff_name );
  }
  $INC{"DirSearchRec.pm"} = 1;
}

1
