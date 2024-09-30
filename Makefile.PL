use 5.008;
use strict;
use warnings;

use ExtUtils::MakeMaker 6.64;

WriteMakefile(
  MIN_PERL_VERSION  => '5.014',
  NAME              => 'TVision',
  AUTHOR            => 'J. Schneider',
  VERSION_FROM      => 'lib/TurboVision/Objects.pm',
  ABSTRACT          => 'Turbo Vision is a character-mode text user '.
                       'interface framework.',
  CONFIGURE_REQUIRES  => {
    'ExtUtils::MakeMaker' => 6.64,
  },
  PREREQ_PM => {
    'Bit::Vector::Str'          => 7.4,
    'Carp'                      => 1.17,
    'constant::boolean'         => 0.02,
    'Contextual::Return'        => 0.004014,
    'Data::Alias'               => 1.21,
    'Devel::Assert'             => 1.06,
    'Devel::StrictMode'         => 0.003,
    'Function::Parameters'      => 2.001003,
    'Import::Into'              => 1.002005,
    'Moose'                     => 2.1213,
    'MooseX::ClassAttribute'    => 0.27,
    'MooseX::HasDefaults'       => 0.03,
    'MooseX::Singleton'         => 0.30,
    'MooseX::StrictConstructor' => 0.21,
    'MooseX::Types::Common'     => 0.001014,
    'MooseX::Types::Perl'       => 0.101343,
    'namespace::autoclean'      => 0.25,
    'List::Util'                => 0,
    'Scalar::Util'              => 0,
    'Try::Tiny'                 => 0.22,
    'Win32'                     => 0,
    'Win32API::File'            => 0.1101,
    'Win32::API'                => 0.84,
    'Win32::Console'            => '0.10',
  },
  TEST_REQUIRES => {
    'Devel::Refcount' => 0.10,
    'Test::Exception' => 0.43,
    'Test::More'      => 0.95,
    'Win32::GuiTest'  => 1.64,
  },
  LICENSE     => 'lgpl_3_0',
  dist        => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  test        => { TESTS => 't/*.t t/*/*.t' },
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
