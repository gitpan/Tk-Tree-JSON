use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tk::Tree::JSON',
    AUTHOR              => 'José Santos <santos.swdev@gmail.com>',
    VERSION_FROM        => 'lib/Tk/Tree/JSON.pm',
    ABSTRACT_FROM       => 'lib/Tk/Tree/JSON.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tk-Tree-JSON-*' },
);
