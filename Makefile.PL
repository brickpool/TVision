use 5.008;
use strict;
use warnings;

use ExtUtils::MakeMaker 6.64;

WriteMakefile(
  MIN_PERL_VERSION  => '5.010',
  NAME              => 'TVision',
  AUTHOR            => 'J. Schneider',
  VERSION_FROM      => 'lib/TV/Objects/Object.pm',
  ABSTRACT          => 'Turbo Vision is a character-mode text user '.
                       'interface framework.',
  CONFIGURE_REQUIRES  => {
    'ExtUtils::MakeMaker' => 6.64,
  },
  PREREQ_PM => {
    'base'              => 0,
    'Carp'              => 1.17,
    'Class::LOP'        => 0.003,
    'Devel::Assert'     => 1.06,
    'Devel::StrictMode' => 0.003,
    'List::Util'        => 1.33,
    'Module::Loaded'    => 0,
    'Scalar::Util'      => 1.36,
    'UNIVERSAL::Object' => 0.17,
    'Win32'             => 0.59,
    'Win32API::File'    => 0.1101,
    'Win32::API'        => 0.84,
    'Win32::Console'    => '0.10',
    },
  TEST_REQUIRES => {
    'Test::Exception' => 0.43,
    'Test::More'      => 0.95,
  },
  LICENSE     => 'mit',
  dist        => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  test        => { TESTS => 't/TV/*.t t/TV/*/*.t' },
  META_MERGE  => {
    'meta-spec' => { version => 2 },
    resources => {
      repository  => {
        type => 'git',
        url  => 'https://github.com/brickpool/TVision.git',
        web  => 'https://github.com/brickpool/TVision',
      },
      bugtracker  => { web => 'https://github.com/brickpool/TVision/issues' },
      homepage    => 'http://brickpool.de',
    },
  },
);
