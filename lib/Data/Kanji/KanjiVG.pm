package Data::Kanji::KanjiVG;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/parse/;
use warnings;
use strict;
our $VERSION = 0.03;
use XML::Parser::Expat;
use Carp;
use Image::SVG::Path 'extract_path_info';

sub parse
{
    my (%inputs) = @_;
    my %kanjis;
    my $callback = $inputs{callback};
    if ($callback) {
        if (ref $callback ne 'CODE') {
            croak "Callback is not a code reference";
        }
        $kanjis{callback} = $callback;
        $kanjis{callback_data} = $inputs{callback_data};
    }
    $kanjis{flatten} = $inputs{flatten};
    $kanjis{parse_svg} = $inputs{parse_svg};
    if ($kanjis{parse_svg}) {
        $kanjis{flatten} = 1;
    }
    $kanjis{kanji} = {};
    my $p = XML::Parser::Expat->new ();
    $p->setHandlers (
        Start => sub {
            start (\%kanjis, @_);
        },
        End => sub {
            end (\%kanjis, @_);
        },
    );
    my $file_name = $inputs{file_name};
    if ($file_name) {
        if (! -f $file_name) {
            croak "File '$file_name' does not exist";
        }
        open my $file, "<:encoding(utf8)", $file_name or die $!;
        $p->parse ($file);
        close $file or die $!;
    }
    elsif ($inputs{xml}) {
        my $xml = $inputs{xml};
        $p->parse ($xml);
    }
    else {
        carp "Nothing to parse: specify input with 'file_name' or 'xml'";
    }
}

# <tag>

sub start
{
    my ($kanjis, $parser, $element, %attr) = @_;
    if ($kanjis->{verbose}) {
        print "Open $element\n";
    }
    my $kanji = $kanjis->{kanji};
    if ($element eq 'kanji') {
        $kanji->{g} = [];
        $kanji->{attr} = \%attr;
    }
    elsif ($element eq 'g') {
        my $sub_g = {
            type => 'g',
            attr => \%attr,
            paths => [],
        };
        if (@{$kanji->{g}}) {
            my $g = $kanji->{g}->[-1];
            push @{$g->{paths}}, $sub_g;
        }
        else {
            $kanji->{main_g} = $sub_g;
        }
        push @{$kanji->{g}}, $sub_g;
    }
    elsif ($element eq 'path') {
        my $g = $kanji->{g}->[-1];
        push @{$g->{paths}}, {
            type => 'path',
            attr => \%attr,
        };
    }
    elsif ($element eq 'kanjivg') {
        $kanjis->{mode} = 'combined';
    }
    else {
        warn "Unknown opening element '$element'";
    }
}

# </tag>

sub end
{
    my ($kanjis, $parser, $element) = @_;
    if ($kanjis->{verbose}) {
        print "Close $element.\n";
    }
    my $kanji = $kanjis->{kanji};
    if ($element eq 'kanji') {
        my $callback = $kanjis->{callback};
        if ($callback) {
            my $flatten = $kanjis->{flatten};
            if ($flatten) {
                my $flattened = flatten ($kanji);
                if ($kanjis->{parse_svg}) {
                    my $parsed_svg = parse_svg ($flattened);
                    if (ref $parsed_svg ne 'ARRAY') {
                        die "Not an array reference";
                    }
                    &{$callback} ($kanjis->{callback_data}, $parsed_svg);
                }
                else {
                    &{$callback} ($kanjis->{callback_data}, $flattened);
                }
            }
            else {
                &{$callback} ($kanjis->{callback_data}, $kanji);
            }
        }
        # Reset the input kanji field.
        $kanjis->{kanji} = {};
    }
    elsif ($element eq 'g') {
        pop @{$kanji->{g}};
    }
    elsif ($element eq 'path') {
        # Nothing needs to be done
    }
    elsif ($element eq 'kanjivg') {
        # Nothing needs to be done
    }
    else {
        warn "Unknown closing element '$element'";
    }
}

# Parse the SVG paths into a more useable format.

sub parse_svg
{
    my ($flattened) = @_;
    my @parsed_svg;
    if (! @$flattened) {
        croak "Empty list of paths";
    }
    for my $element (@$flattened) {
        my $id = $element->{id};
        my $d = $element->{d};
        if (!$d) {
            croak "Element '$id' has no 'd' attribute";
        }
        my @parsed = extract_path_info ($d, {
            absolute => 1,
            no_shortcuts => 1,
        });
        if (! @parsed) {
            croak "Path '$d' is empty";
        }
        push @parsed_svg, \@parsed;
    }
    print "Parsed SVG: @parsed_svg\n";
    return \@parsed_svg;
}

# Turn the structure of hash references into a single array containing
# the paths in order, and return a reference to the array.

sub flatten
{
    my ($kanji) = @_;
    my ($g) = $kanji->{main_g};
    my @flattened;
    follow ($g, \@flattened);
    return \@flattened;
}

sub follow
{
    my ($g, $flattened) = @_;
    for my $path (@{$g->{paths}}) {
        if ($path->{type} eq 'g') {
#            print "Group.\n";
            follow ($path, $flattened);
        }
        elsif ($path->{type} eq 'path') {
            push @$flattened, $path->{attr};
        }
        else {
            die "Unknown or undefined path type in kanji group";
        }
    }
}

1;

