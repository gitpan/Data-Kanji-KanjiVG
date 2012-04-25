use strict;
use warnings;
use ExtUtils::MakeMaker;

my $name = 'Data::Kanji::KanjiVG';
my $pm = "lib/$name.pm";
$pm =~ s!::!/!g;
my $pod = $pm;
$pod =~ s!\.pm$!.pod!;
my $repo = "https://github.com/benkasminbullock/$name";
$repo =~ s!::!-!g;

WriteMakefile (
    NAME => $name,
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
        'XML::Parser' => '0',
        'Image::SVG::Path' => '0.06',
    },
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
    },
);
