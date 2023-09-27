use 5.008;
use strict;
use warnings;

use ExtUtils::MakeMaker 6.64;

WriteMakefile(
  MIN_PERL_VERSION    => '5.014',
  NAME                => 'TVision',
  AUTHOR              => 'J. Schneider',
  VERSION_FROM        => 'lib/Objects.pm',
  ABSTRACT_FROM       => 'lib/Objects.pm',
  CONFIGURE_REQUIRES  => {
    'ExtUtils::MakeMaker' => 6.64,
  },
  PREREQ_PM => {
    'Carp'                        => 1.17,
    'constant::boolean'           => 0.02,
    'Contextual::Return'          => 0.004014,
    'Data::Alias'                 => 1.21,
    'Devel::StrictMode'           => 0.003,
    'Function::Parameters'        => 2.001003,
    'Import::Into'                => 1.002005,
    'Moose'                       => 2.1213,
    'MooseX::ClassAttribute'      => 0.29,
    'MooseX::HasDefaults::RO'     => 0.03,
    'MooseX::Singleton'           => 0.30,
    'MooseX::StrictConstructor'   => 0.21,
    'MooseX::Types::Common'       => 0.001014,
    'MooseX::Types::Perl'         => 0.101343,
    'namespace::autoclean'        => 0.25,
    'PerlX::Assert'               => 0.905,
    'Scalar::List::Utils'         => 1.55,
    'Try::Tiny'                   => 0.22,
  },
  TEST_REQUIRES => {
    'Devel::Refcount' => 0.10,
    'Test::Exception' => 0.43,
    'Test::More'      => 0.95,
    'Win32::GuiTest'  => 1.64,                # Win32
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
