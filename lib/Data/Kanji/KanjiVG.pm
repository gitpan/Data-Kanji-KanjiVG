=head1 NAME

Data::Kanji::KanjiVG - parse KanjiVG kanji data.

=cut
package Data::Kanji::KanjiVG;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/parse/;
use warnings;
use strict;
our $VERSION = 0.02;
use XML::Parser::Expat;
use Carp;

=head2 parse

    parse (
        file_name => $file_name,
        callback => $callback,
        callback_data => $callback_data,
    );

Parse the file specified by C<$file_name>. As a complete piece of
kanji data is achieved, call C<$callback> in the following form:

    &{$callback} ($callback_data, $kanji);

Possible arguments are

=over

=item file_name

Give the name of the file to parse.

=item callback

Give a function to call back each time a complete piece of kanji
information is parsed.

=item callback_data

An optional piece of data to pass to the callback function.

=item flatten

A boolean. If it is false (or if it is omitted), the kanji information
is sent as a complete hash reference. If it is true, the kanji
information is sent as an array reference containing the paths.

=back

If the data is not flattened using C<flatten>, C<$kanji> is a hash
reference containing the following fields:

=over

=item id

The identification number of the kanji.

=item g

A group of strokes of the kanji. This contains the following sub-fields:

=over

=item paths

An array reference to strokes or groups of strokes. Each element
contains its type and attributes.

=back

=back

Each path is a single stroke of the kanji. This hash reference contains the
following sub-fields:

=over

=item id

The stroke's identification number.

=item type

The type of the stroke, a field describing the general shape of the
stroke.

=item d

The SVG path information. This information is a string. To parse it,
the module L<Image::SVG::Path> may be useful.

=back

=cut

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
                &{$callback} ($kanjis->{callback_data}, $flattened);
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
