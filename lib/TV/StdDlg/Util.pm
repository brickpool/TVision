package TV::StdDlg::Util;
# ABSTRACT: defines utility functions used for Turbo Vision Standard Dialogs

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000_001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT_OK = qw(
  fexpand
  getCurDir
  getHomeDir
);

use PerlX::Assert::PP;
use Scalar::Util qw( readonly );
use TV::toolkit::Params qw( signature );
use TV::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TV::StdDlg::Const qw(
  DIRECTORY
  :MAX
);
use TV::StdDlg::Dir qw(
  fnsplit
  fnmerge
  getdisk
  getcurdir
);

my (
  $skip,
  $squeeze,
  $isSep,
  $isHomeExpand,
  $isAbsolute,
  $addFinalSep,
  $getPathDrive,
);

$skip = sub {    # void ($src, $k)
  my ( $src, $k ) = @_;
  assert ( @_ == 2 );
  assert ( is_Str $src );
  assert ( is_Str $k );
  while ( length( $src ) && substr( $src, 0, 1 ) eq $k ) {
    substr( $src, 0, 1, '' );
  }
  $_[0] = $src;
  return;
};

$squeeze = sub {   # void ($path)
  my ( $path ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $path );
  assert ( not readonly $_[0] );

  my $dest = '';
  my $src  = $path;
  my $last = '';

  while ( length $src ) {
    if ( $last eq '\\' ) {
      $skip->( $src, '\\' );    # skip repeated '\'
    }
    if ( ( !$last || $last eq '\\' ) && substr( $src, 0, 1 ) eq '.' ) {
      substr( $src, 0, 1, '' );

      # have a '.' or '.\'
      if ( !length( $src ) || substr( $src, 0, 1 ) eq '\\' ) {
        $skip->( $src, '\\' );
      }

      # have a '..' or '..\'
      elsif ( substr( $src, 0, 1 ) eq '.'
        && ( length( $src ) == 1 || substr( $src, 1, 1 ) eq '\\' ) )
      {

        # skip the following '.'
        substr( $src, 0, 1, '' );
        $skip->( $src, '\\' );

        # back up to previous '\'
        substr( $dest, -1, 1, '' ) if length( $dest );

        # back up to previous '\'
        while ( length( $dest ) && substr( $dest, -1, 1 ) ne '\\' ) {
          substr( $dest, -1, 1, '' );
        }

        # move to the next position
        $last = length( $dest ) ? substr( $dest, -1, 1 ) : '';
      } #/ elsif ( substr( $src, 0, ...))
      else {
        # copy the '.' we just skipped
        $dest .= $last = '.';
      }
    } #/ if ( ( $last eq "\0" ||...))
    else {
      # copy first char from src to dest
      my $c = substr( $src, 0, 1, '' );
      $dest .= $c;
      $last = $c;
    }
  } #/ while ( length( $src ) )

  # Perl string needs no zero terminator
  $_[0] = $dest;
  return;
}; #/ sub squeeze_inplace

$isSep = sub {    # $bool ($c)  
  my ( $c ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $c );
  return ( $c eq '\\' || $c eq '/' );
};

$isHomeExpand = sub {   # $bool ($path)
  my ( $path ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $path );
  my @path = map { substr( $path, $_, 1 ) // '' } 0 .. 1;
  return $path[0] eq '~' && $isSep->( $path[1] );
};

$isAbsolute = sub {   # $bool ($path)
  my ( $path ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $path );
  my @path = map { substr( $path, $_, 1 ) // '' } 0 .. 2;
  return $isSep->( $path[0] ) 
      || ( $path[0] && $path[1] eq ':' && $isSep->( $path[2] ) );
};

$addFinalSep = sub {    # void ($path, $size)
  my ( $path, $size ) = @_;
  assert ( @_ == 2 );
  assert ( is_Str $path );
  assert ( is_Int $size );
  assert ( not readonly $_[0] );
  if ( $size < 1 && length( $path ) < $size ) {
    $path .= '\\';
    $_[0] = $path;
  }
  return;
};

$getPathDrive = sub {    # $int ($path)
  my ( $path ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $path );
  my @path = map { substr( $path, $_, 1 ) // '' } 0 .. 1;
  if ( $path[0] && $path[1] eq ':' ) {
    my $drive = ord( uc $path[0] ) - ord( 'A' );
    if ( 0 <= $drive && $drive <= ord( 'Z' ) - ord( 'A' ) ) {
      return $drive;
    }
  }
  return -1;
};

sub getHomeDir {    # $bool ($drive, $dir)
  state $sig = signature(
    pos => [ Maybe[Str], Maybe[Str] ],
  );
  my ( $drive, $dir ) = $sig->( @_ );
  assert ( !defined or !readonly $_[0] );
  assert ( !defined or !readonly $_[1] );
  if ( $^O eq 'MSWin32' ) {
    my $homedrive = $ENV{"HOMEDRIVE"};
    my $homepath  = $ENV{"HOMEPATH"};
    if ( $homedrive && $homepath ) {
      if ( defined $drive ) {
        $_[0] = $drive = substr( $homedrive, 0, MAXDRIVE );
      }
      if ( defined $dir ) {
        $_[1] = $dir = substr( $homepath, 0, MAXDIR );
      }
      return !!1;
    }
  } 
  else {
    my $home = $ENV{"HOME"};
    if ( $home ) {
      if ( defined $drive ) {
        $_[0] = $drive = '';
      }
      if ( defined $dir ) {
        $_[1] = $dir = substr( $home, 0, MAXPATH );
      }
      return !!1;
    }
  }
  return !!0;
}

sub getCurDir {    # void ($dir, $drive)
  state $sig = signature(
    pos => [
      Str, 
      Int, { default => -1 },
    ],
  );
  my ( $dir, $drive ) = $sig->( @_ );
  assert ( not readonly $_[0] );
  $drive = getdisk() unless 0 <= $drive && $drive <= ord( 'Z' ) - ord( 'A' );
  $dir = chr( $drive + ord( 'A' ) ) . ':\\';
  getcurdir( $drive + 1, my $tmp );
  substr( $dir, 3 ) = $tmp;
  $dir .= '\\' if length $tmp;
  substr( $dir, MAXPATH ) = '' if length $dir > MAXPATH;
  $_[0] = $dir;
  return;
}

sub fexpand {    # void ($rpath, |$relativeTo)
  state $sig = signature( 
    pos => [
      Str, 
      Str => { optional => 1 },
    ],
  );
  my ( $rpath, $relativeTo ) = $sig->( @_ );
  assert ( not readonly $_[0] );
  unless ( defined $relativeTo ) {
    $relativeTo = '';
    getCurDir( $relativeTo, $getPathDrive->($rpath) );
  }
  my $fn = {
    drive => '',
    dir   => '',
    file  => '',
    ext   => '',
  };
  my $path = '';

  my $drv;
  # Prioritize drive letter in 'rpath'.
  if ( ( $drv = $getPathDrive->( $rpath ) ) == -1 
    && ( $drv = $getPathDrive->( $relativeTo ) ) == -1 
  ) {
    $drv = getdisk();
  }
  $fn->{drive} = chr( ord('A') + $drv );
  $fn->{drive} .= ':';

  my $flags = fnsplit( $rpath, undef, $fn->{dir}, $fn->{file}, $fn->{ext} );
  if ( ( $flags & DIRECTORY ) == 0 || !$isSep->( substr $fn->{dir}, 0, 1 ) ) {
    my $rbase = '';
    if ( $isHomeExpand->( $fn->{dir} ) && getHomeDir( $fn->{drive}, $rbase ) ) {
      # Home expansion. Overwrite drive if necessary.
      # 'dir' begins with "~/" or "~\", so we can reuse the separator.
      $rbase .= substr( $fn->{dir}, 1 );
      $rbase = substr( $rbase, 0, MAXDIR ) if length $rbase > MAXDIR;
    }
    else {
      # If 'rpath' is relative but contains a drive letter, just swap drives.
      if ( $getPathDrive->( $rpath ) != -1 ) {
        if ( getcurdir( $drv + 1, $rbase ) != 0 ) {
          $rbase = '';
        }
      }
      else {
        # Expand 'relativeTo'.
        $rbase = substr( $relativeTo, 0, MAXPATH );
        if ( !$isAbsolute->( $rbase ) ) {
          my $curpath = '';
          getCurDir( $curpath, $drv );
          fexpand( $rbase, $curpath );
        }

        # Skip drive letter in 'rbase' (remove "C:")
        if ( $getPathDrive->( $rbase ) != -1 ) {
          substr( $rbase, 0, 2, '' );
        }
      }

      # Ensure 'rbase' ends with a separator.
      $addFinalSep->( $rbase, MAXPATH );
      $rbase .= $fn->{dir};
      $rbase = substr( $rbase, 0, MAXDIR ) if length $rbase > MAXDIR;
    } #/ else [ if ( $isHomeExpand->( $fn->{dir}...))]

    if ( !$isSep->( substr( $rbase, 0, 1 ) ) ) {
      $fn->{dir} = substr( '\\' . $rbase, 0, MAXDIR );
    }
    else {
      $fn->{dir} = substr( $rbase, 0, MAXDIR );
    }
  } #/ if ( ( ( $flags & $DIRECTORY...)))

  $fn->{dir} =~ tr{/}{\\};
  $squeeze->( $fn->{dir} );
  fnmerge( $path, $fn->{drive}, $fn->{dir}, $fn->{file}, $fn->{ext} );
  $path = uc $path;
  $_[0] = $rpath = substr( $path, 0, MAXPATH );
  return;
}

1
