package String::Util::Range;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(convert_sequence_to_range);
our %SPEC;

$SPEC{'convert_sequence_to_range'} = {
    v => 1.1,
    summary => 'Find sequences in arrays & convert to range '.
        '(e.g. "a","b","c","d","x",1,2,3,4,"x" -> "a..d","x","1..4","x")',
    description => <<'_',

Sequence follows Perl's autoincrement notion, e.g. 1->2, "aa"->"ab", "az"->"ba",
"01"->"02", "ab1"->"ab2".

_
    args => {
        array => {
            schema => ['array*', of=>'str*'],
            pos => 0,
            greedy => 1,
            cmdline_src => 'stdin_or_args',
        },
        threshold => {
            schema => 'posint*',
            default => 4,
        },
        separator => {
            schema => 'str*',
            default => '..',
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
            summary => 'option: separator',
            args => {
                array => [1,2,3,4, "x", "a","b","c","d"],
                separator => '-',
            },
            result => ["1-4","x","a-d"],
        },
        {
            summary => 'option: threshold',
            args => {
                array => [1,2,3,4, "x", "a","b","c","d","e"],
                threshold => 5,
            },
            result => [1,2,3,4, "x", "a..e"],
        },
    ],
};
sub convert_sequence_to_range {
    my %args = @_;

    my $array = $args{array};
    my $threshold = $args{threshold} // 4;
    my $separator = $args{separator} // '..';

    my @res;
    my @buf; # to hold possible sequence

    my $code_empty_buffer = sub {
        return unless @buf;
        push @res, @buf >= $threshold ? ("$buf[0]$separator$buf[-1]") : @buf;
        @buf = ();
    };

    for my $i (0..$#{$array}) {
        my $el = $array->[$i];
        if (@buf) {
            (my $buf_inc = $buf[-1])++;
            if ($el ne $buf_inc) { # breaks current sequence
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
