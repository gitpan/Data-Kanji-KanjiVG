use warnings;
use strict;
use Test::More ;# tests => 1;
BEGIN { use_ok('Data::Kanji::KanjiVG') };
use Data::Kanji::KanjiVG 'parse';
use utf8;

# Set up outputs to not print wide character warnings (this is for
# debugging this file, not for the end-user's benefit).

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":utf8";

my $xml = <<'EOF';
<kanji id="kvg:kanji_04e09">
<g id="kvg:04e09" kvg:element="三">
	<g id="kvg:04e09-g1" kvg:element="一" kvg:position="top" kvg:radical="general">
		<path id="kvg:04e09-s1" kvg:type="㇐" d="M27.5,23.65c3.09,0.73,6.29,0.36,9.4,0.06c10.2-1,27-2.94,38.97-3.57c3.06-0.16,6.09-0.2,9.14,0.23"/>
	</g>
	<g id="kvg:04e09-g2" kvg:position="bottom">
		<g id="kvg:04e09-g3" kvg:element="一" kvg:radical="general">
			<path id="kvg:04e09-s2" kvg:type="㇐" d="M28.75,55.14c3.13,0.76,6.46,0.43,9.64,0.2c10.03-0.72,23.97-2.63,34.73-3.12c2.7-0.12,5.45-0.16,8.13,0.3"/>
		</g>
		<g id="kvg:04e09-g4" kvg:element="一" kvg:radical="general">
			<path id="kvg:04e09-s3" kvg:type="㇐" d="M13,87.83c3.94,1.01,7.72,0.96,11.75,0.72c18.41-1.07,41.27-3.39,61.12-4.07c3.63-0.13,7.2-0.1,10.75,0.78"/>
		</g>
	</g>
</g>
</kanji>
EOF

my $cbd = 'callback_data';

parse (
    xml => $xml,
    callback => \& callback,
    callback_data => $cbd,
);

parse (
    xml => $xml,
    callback => \& flat_callback,
    callback_data => $cbd,
    flatten => 1,
);

parse (
    xml => $xml,
    callback => \& svg_callback,
    callback_data => $cbd,
    parse_svg => 1,
);

done_testing ();

#parse (
#    file_name => '/home/ben/projects/kanjivg/kanjivg-20120401.xml',
#    callback => \& callback,
#);

exit;

sub svg_callback
{
    my ($callback_data, $parsed_svg) = @_;
    ok ($callback_data eq $cbd, "Callback data OK");
    for my $path (@$parsed_svg) {
        for my $curve (@$path) {
            my $type = $curve->{type};
            ok (defined $type);
            # Check that everything is "absolute" not relative and not
            # shortcut.
            ok ($curve->{position} eq 'absolute');
            ok ($type eq 'cubic-bezier' || $type eq 'moveto');
        }
    }
}

sub flat_callback
{
    my ($callback_data, $flattened) = @_;
    ok ($callback_data eq $cbd, "Callback data OK");
    ok (ref $flattened eq 'ARRAY', "Got array reference");
    ok (@$flattened eq 3, "Right number of members in array");
    for my $path (@$flattened) {
        ok ($path->{id} =~ /^kvg:04e09-s\d$/, "Got correct path");
    }
}

sub callback
{
    my ($callback_data, $kanji) = @_;
    ok ($callback_data eq $cbd, "Callback data OK");
    my $element = $kanji->{attr}{'id'};
    my $c = '';
    if ($element =~ /kvg:kanji_([0-9a-fA-F]+)/) {
        my $value = hex $1;
        $c = chr ($value);
    }
    print "$element $c\n";

    my $main_g = $kanji->{main_g};
    follow ($main_g);
}

sub follow
{
    my ($g) = @_;
    for my $path (@{$g->{paths}}) {
        if ($path->{type} eq 'g') {
#            print "Group.\n";
            follow ($path);
        }
        elsif ($path->{type} eq 'path') {
            my $attr = $path->{attr};
            #my $d = $attr->{d};
            print "Path $attr->{id} $attr->{d}\n";
        }
    }
}


# Local variables:
# mode: perl
# End:
