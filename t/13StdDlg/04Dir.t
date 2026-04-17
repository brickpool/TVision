use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TV::StdDlg::Const', qw( :DIR );
  use_ok 'TV::StdDlg::Dir', qw(
    fnmerge
    fnsplit
    getdisk
    setdisk
    getcurdir
  );
}

#--------------
note 'fnmerge';
#--------------
subtest 'fnmerge basic behaviour' => sub {
  my $path;

  fnmerge( $path, 'C', 'foo', 'bar', 'txt' );

  if ( $^O eq 'MSWin32' ) {
    is( $path, 'C:foo\\bar.txt', 'Windows: drive + dir + name + ext' );
  }
  else {
    is( $path, 'foo/bar.txt', 'Unix: drive ignored, unix separators' );
  }

  fnmerge( $path, undef, 'foo/', 'bar', '.txt' );
  is(
    $path,
    'foo/bar.txt',
    'Existing directory separator preserved, no duplication'
  );
}; #/ 'fnmerge basic behaviour' => sub

#--------------
note 'fnsplit';
#--------------
subtest 'fnsplit components' => sub {
  my ( $d, $dir, $n, $e );

  my $flags = fnsplit( 'C:\\foo\\bar.txt', $d, $dir, $n, $e );

  is( $d,   'C:',      'drive extracted' );
  is( $dir, '\\foo\\', 'dir extracted with trailing separator' );
  is( $n,   'bar',     'filename extracted' );
  is( $e,   '.txt',    'extension extracted with dot' );

  ok( $flags & DRIVE(),     'DRIVE() flag set' );
  ok( $flags & DIRECTORY(), 'DIRECTORY() flag set' );
  ok( $flags & FILENAME(),  'FILENAME() flag set' );
  ok( $flags & EXTENSION(), 'EXTENSION() flag set' );
};

subtest 'fnsplit special dot cases' => sub {
  my ( $d, $dir, $n, $e );

  my $flags = fnsplit( 'foo\\.', undef, $dir, $n, $e );

  is( $dir, 'foo\\.', 'dot directory treated as directory' );
  is( $n,   '',       'no filename for trailing dot' );
  is( $e,   '',       'no extension for trailing dot' );
};

subtest 'fnsplit wildcards' => sub {
  my $flags = fnsplit( 'foo\\*.txt', undef, undef, undef, undef );

  ok( $flags & WILDCARDS(), 'wildcards detected in filename part' );

  $flags = fnsplit( 'foo*\\bar.txt', undef, undef, undef, undef );

  ok( !( $flags & WILDCARDS() ), 'wildcards ignored in directory part' );
};

#--------------
note 'getdisk';
#--------------
subtest 'getdisk' => sub {
  my $d = getdisk();

  ok( defined $d,          'getdisk returns a value' );
  ok( $d >= 0 && $d <= 25, 'getdisk returns valid drive index' );
};

#----------------
note 'getcurdir';
#----------------
subtest 'getcurdir' => sub {
  my $dir;
  my $rc = getcurdir( 0, $dir );

  is( $rc, 0, 'getcurdir returns success for default drive' );
  ok( defined $dir, 'directory string returned' );
  ok( $dir !~ /^[A-Za-z]:/, 'no drive letter in result' );
  ok( $dir !~ m{^[/\\]},    'no leading slash or backslash' );
};

#--------------
note 'setdisk';
#--------------
subtest 'setdisk' => sub {
  my $cur = getdisk();

  my $rc = setdisk( $cur + 1 );

  if ( $^O eq 'MSWin32' ) {
    ok( $rc > 0, 'setdisk returns number of drives on Windows' );
  }
  else {
    is( $rc, 0, 'setdisk succeeds only for current drive on Unix' );
  }

  is( getdisk(), $cur, 'current drive unchanged or restored' );
};

#-------------------------
note 'findfirst/findnext';
#-------------------------
subtest 'findfirst/findnext' => sub {
  can_ok( 'TV::StdDlg::Dir', 'findfirst' );
  can_ok( 'TV::StdDlg::Dir', 'findnext' );
};

done_testing();

__END__

#--------------
note 'fexpand';
#--------------
subtest 'fexpand basic expansion' => sub {
  my $path;

  # relative path
  $path = 'foo/bar.txt';
  fexpand( $path );

  if ( $^O eq 'MSWin32' ) {
    like(
      $path,
      qr{^[A-Z]:\\},
      'Windows: relative path expanded to absolute with drive'
    );
    like(
      $path,
      qr{foo\\bar\.txt$},
      'Windows: path suffix preserved'
    );
  }
  else {
    like(
      $path,
      qr{^/},
      'Unix: relative path expanded to absolute'
    );
    like(
      $path,
      qr{foo/bar\.txt$},
      'Unix: path suffix preserved'
    );
  }
}; #/ 'fexpand basic expansion' => sub

subtest 'fexpand dot and dotdot' => sub {
  my $path;

  $path = 'a/./b/../c';
  fexpand( $path );

  if ( $^O eq 'MSWin32' ) {
    like(
      $path,
      qr{\\a\\c$},
      'Windows: "." and ".." collapsed correctly'
    );
  }
  else {
    like(
      $path,
      qr{/a/c$},
      'Unix: "." and ".." collapsed correctly'
    );
  }
}; #/ 'fexpand dot and dotdot' => sub

subtest 'fexpand mixed separators' => sub {
  my $path;

  $path = 'a\\b/c\\d';
  fexpand( $path );

  if ( $^O eq 'MSWin32' ) {
    like(
      $path,
      qr{\\a\\b\\c\\d$},
      'Windows: mixed separators normalized to backslash'
    );
  }
  else {
    like(
      $path,
      qr{/a/b/c/d$},
      'Unix: mixed separators normalized to slash'
    );
  }
}; #/ 'fexpand mixed separators' => sub

subtest 'fexpand drive-relative path' => sub {
  my $path;

  $path = 'C:foo\\bar';
  fexpand( $path );

  if ( $^O eq 'MSWin32' ) {
    like(
      $path,
      qr{^C:\\},
      'Windows: C:relative path expanded using drive C cwd'
    );
    like(
      $path,
      qr{foo\\bar$},
      'Windows: path suffix preserved'
    );
  }
  else {
    pass( 'Unix: drive-relative paths are not applicable' );
  }
}; #/ 'fexpand drive-relative path' => sub

subtest 'fexpand rooted path without drive' => sub {
  my $path;

  $path = '\\foo\\bar';
  fexpand( $path );

  if ( $^O eq 'MSWin32' ) {
    like(
      $path,
      qr{^[A-Z]:\\foo\\bar$},
      'Windows: rooted path uses current drive'
    );
  }
  else {
    pass( 'Unix: backslash-rooted path not applicable' );
  }
};

subtest 'fexpand home expansion' => sub {
  my $path = '~/testdir/file.txt';
  fexpand( $path );

  if ( $^O ne 'MSWin32' ) {
    like(
      $path,
      qr{^/},
      'Unix: ~/ expanded to absolute home directory'
    );
    like(
      $path,
      qr{/testdir/file\.txt$},
      'Unix: home expansion preserves suffix'
    );
  }
  else {
    pass( 'Windows: home expansion not supported' );
  }
}; #/ 'fexpand home expansion' => sub

subtest 'fexpand idempotency' => sub {
  my $path;

  $path = 'foo/bar';
  fexpand( $path );
  my $once = $path;

  fexpand( $path );
  my $twice = $path;

  is(
    $twice,
    $once,
    'fexpand is idempotent (second call does not change path)'
  );
};

