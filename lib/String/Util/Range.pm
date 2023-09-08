package String::Util::Range;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

# AUTHORITY
# DATE
# DIST
# VERSION

our @EXPORT_OK = qw(convert_sequence_to_range);

our %SPEC;

$SPEC{'convert_sequence_to_range'} = {
    v => 1.1,
    summary => 'Find sequences in arrays & convert to range '.
        '(e.g. "a","b","c","d","x",1,2,3,4,"x" -> "a..d","x","1..4","x")',
    description => <<'_',

This routine accepts an array, finds sequences in it (e.g. 1, 2, 3 or aa, ab,
ac, ad), and converts each sequence into a range ("1..3" or "aa..ad"). So
basically it "compresses" the sequence (many elements) into a single element.

What determines a sequence is Perl's autoincrement magic (see the `perlop`
documentation on the Auto-increment), e.g. 1->2, "aa"->"ab", "az"->"ba",
"01"->"02", "ab1"->"ab2".

_
    args => {
        array => {
            schema => ['array*', of=>'str*'],
            pos => 0,
            slurpy => 1,
            cmdline_src => 'stdin_or_args',
        },
        min_range_len => {
            schema => ['posint*', min=>2],
            default => 4,
            description => <<'MARKDOWN',

Minimum number of items in a sequence to convert to a range. Sequence that has
less than this number of items will not be converted.

MARKDOWN
        },
        max_range_len => {
            schema => ['posint*', min=>2],
            description => <<'MARKDOWN',

Maximum number of items in a sequence to convert to a range. Sequence that has
more than this number of items might be split into two or more ranges.

MARKDOWN
        },
        separator => {
            schema => 'str*',
            default => '..',
        },
        ignore_duplicates => {
            schema => 'true*',
        },
    },
    result_naked => 1,
    examples => [
        {
            summary => 'basic',
            args => {
                array => [1,2,3,4, "x", "a","b","c","d"],
            },
            result => ["1..4","x","a..d"],
        },
        {
            summary => 'option: min_range_len (1)',
            args => {
                array => [1,2,3, "x", "a","b","c"],
                min_range_len => 3,
            },
            result => ["1..3","x","a..c"],
        },
        {
            summary => 'option: min_range_len (2)',
            args => {
                array => [1,2,3,4, "x", "a","b","c","d"],
                min_range_len => 5,
            },
            result => [1,2,3,4,"x","a","b","c","d"],
        },
        {
            summary => 'option: max_range_len',
            args => {
                array => [1,2,3,4,5,6,7, "x", "a","b","c","d","e","f","g"],
                min_range_len => 3,
                max_range_len => 3,
            },
            result => ["1..3","4..6",7,"x","a..c","d..f","g"],
        },
        {
            summary => 'option: separator',
            args => {
                array => [1,2,3,4, "x", "a","b","c","d"],
                separator => '-',
            },
            result => ["1-4","x","a-d"],
        },
        {
            summary => 'option: ignore_duplicates',
            args => {
                array => [1, 2, 3, 4, 2, 9, 9, 9, "a","a","a"],
                ignore_duplicates => 1,
            },
            result => ["1..4", 9,"a"],
        },
    ],
};
sub convert_sequence_to_range {
    my %args = @_;

    my $array = $args{array};
    my $min_range_len = $args{min_range_len} //
        $args{threshold} # old name, DEPRECATED
        // 4;
    my $max_range_len = $args{max_range_len};
    die "max_range_len must be >= min_range_len"
        if defined($max_range_len) && $max_range_len < $min_range_len;
    my $separator = $args{separator} // '..';
    my $ignore_duplicates = $args{ignore_duplicates};

    my @res;
    my @buf; # to hold possible sequence

    my $code_empty_buffer = sub {
        return unless @buf;
        push @res, @buf >= $min_range_len ? ("$buf[0]$separator$buf[-1]") : @buf;
        @buf = ();
    };

    my %seen;
    for my $i (0..$#{$array}) {
        my $el = $array->[$i];

        next if $ignore_duplicates && $seen{$el}++;

        if (@buf) {
            (my $buf_inc = $buf[-1])++;
            if ($el ne $buf_inc) { # breaks current sequence
                $code_empty_buffer->();
            }
            if ($max_range_len && @buf >= $max_range_len) {
                $code_empty_buffer->();
            }
        }
        push @buf, $el;
    }
    $code_empty_buffer->();

    \@res;
}

1;

# ABSTRACT:

=head1 SEE ALSO

L<Data::Dump> also does something similar, e.g. if you say C<< dd
[1,2,3,4,"x","a","b","c","d"]; >> it will dump the array as C<< "[1 .. 4, "x",
"a" .. "d"]" >>.

L<Number::Util::Range> which only deals with numbers.
