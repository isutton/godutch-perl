use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Panamax',
    AUTHOR           => q{Igor Sutton <izut@cpan.org>},
    VERSION_FROM     => 'lib/GoDutch.pm',
    ABSTRACT_FROM    => 'lib/GoDutch.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'IPC::Run'         => 0,
        'AnyEvent::Socket' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'GoDutch-*' },
);
