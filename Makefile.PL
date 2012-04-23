use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Data/Kanji/KanjiVG.pm';
my $repo = 'https://github.com/benkasminbullock/Data-Kanji-KanjiVG';

WriteMakefile (
    NAME => 'Data::Kanji::KanjiVG',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pm,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
        'XML::Parser' => '0',
#        'Image::SVG::Path' => '0.06',
    },
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
    },
);
