package Text::ParagraphDiff;

use strict;
use warnings 'all';
use Algorithm::Diff qw(diff);
use HTML::Entities ();
use POSIX qw(strftime);
use Data::Dumper;
use vars qw(@EXPORT @EXPORT_OK @ISA $VERSION);
require Exporter;
@EXPORT = qw(text_diff);
@EXPORT_OK = qw(create_diff html_header html_footer);
@ISA = qw(Exporter);
$VERSION = "2.20";


sub text_diff {
    return ((html_header(@_)).(create_diff(@_)).(html_footer(@_)));
}

sub create_diff {
    my($old,$new) = (shift,shift);
    my $opt=shift if (@_);

    my $old_orig = _get_lines($old);
    my $new_orig = _get_lines($new);

    my %highlight;
    if ($opt->{plain}) {
        $highlight{minus} = qq(<b><font color="#FF0000" size="+1"> );
        $highlight{plus}  = qq(<b><font color="#005500" size="+1"> );
        $highlight{end} = "</font></b>";
    }
    else {
        $highlight{minus} = qq(<span class="minus"> );
        $highlight{plus}  = qq(<span class="plus"> );
        $highlight{end}   = qq(</span>);
    }

    $opt->{plus_order} = 0 unless $opt->{plus_order};

    my (@old,@old_count);
    foreach (@$old_orig)
    {
        $_ = HTML::Entities::encode($_) unless exists $opt->{escape};
        my @words = (/\S+/g);
        push @old, @words;
        push @old_count, scalar(@words);

    }

    my ($total_diff, @new, @leading_space, @count);
    foreach (@$new_orig)
    {
        my ($leading_white) = /^( *)/;
        push @leading_space, $leading_white;

        $_ = HTML::Entities::encode($_) unless exists $opt->{escape};
        my @words = (/\S+/g);

        push @$total_diff, map { [' ',$_] } @words;
        push @new, @words;
        push @count, scalar(@words);
    }

    $opt->{sep} = ['<p>','</p>'] unless exists $opt->{sep};
    my ($plus,$minus) = _get_diffs(\@old, \@new, \@old_count, $opt->{sep});

    _merge_plus  ($total_diff, $plus) if @$plus;
    _merge_minus ($total_diff, $minus, $opt->{minus_first}) if @$minus;
    _merge_white ($total_diff, \@leading_space);

    $total_diff = _merge_lines ($total_diff, \@count);

    _fold ($total_diff);

    my $output = _format ($total_diff, \%highlight, $opt->{sep});
    return $output;
}

#########
# Utility

sub _get_lines {
    my ($file) = @_;
    my @lines;
    if (!ref $file) {
        open (FILE, "$file") or die "Can't open file $file: $!";
        @lines = <FILE>;
        close(FILE);
        return \@lines;
    }
    else {
        return $file;
    }
}

sub _fold {
    my ($diff) = @_;

    foreach (@$diff) {
        my $i = 0;
        while ($i+1 < @$_) {
            if ($_->[$i][0] eq $_->[$i+1][0]) {
                my $item = splice @$_, $i+1, 1;
                $_->[$i][1] .= (" ".$item->[1]);
                next;
            }
            $i++;
        }
    }
}

sub _get_diffs {
    my ($old,$new,$count,$sep) = @_;
    my @diffs = diff($old, $new);
    my ($plus,$minus) = ([],[]);
    foreach my $hunk (@diffs) {
        foreach (@$hunk) {
            push @$plus,  $_ if $_->[0] eq '+';
            push @$minus, $_ if $_->[0] eq '-';
        }
    }

    _fix_minus ($minus, $count, $sep);

    return ($plus,$minus);
}

sub _fix_minus {

    my ($d,$count,$sep) = @_;
    my ($i,$x) = (0,0);
    foreach my $break (@$count) {
        $i += $break;
        while ( ($x < @$d) && ($i > $d->[$x][1]) ) {
            ++$x
        }
        last unless @$d > $x;
        $d->[$x-1][2] .= $sep->[1].$sep->[0] if (($i-1) == $d->[$x-1][1]);
        ++$x
    }
}

#########
# Merging

sub _merge_plus {
    my ($total_diff, $plus_diff) = @_;

    while ( my $cur = shift @$plus_diff ) {
        $total_diff->[$cur->[1]][0] = '+';
    }
}


sub _merge_minus {
    my ($total_diff, $min_diff, $minus_first) = @_;
    my ($pos,$offset) = (0,0);

    while ( my $cur = shift @$min_diff ) {
        while ($pos < ($cur->[1]+$offset)) {
            ++$offset if $total_diff->[$pos][0] eq '+';
            ++$pos;
        }
        while ($total_diff->[$pos][0] eq '+') {
            ++$offset;
            ++$pos;
        }
        my $current = 0;
        $current = $offset if $minus_first;
        splice @$total_diff, $pos-$current, 0, ['-',$cur->[2]];
    }
}

sub _merge_white {
    my ($total_diff, $whitespace) = @_;
    my $pos = 0;

    while ( @$whitespace ) {
        my $cur = shift @$whitespace;
        while (
                    ($pos < @$total_diff)
                 && ($total_diff->[$pos][0] ne '-')
              ) { $pos++ }
        $total_diff->[$pos][1] = $cur . $total_diff->[$pos][1]
            if $total_diff->[$pos][1];
        ++$pos;
    }
}

sub _merge_lines {
    my ($total_diff, $count) = @_;
    my $new = [];

    foreach my $cur ( @$count ) {

        if ($cur > 0) {
            push @$new, [];
            my ($pos,$neg,$x) = (0)x3;
            while ( $pos < $cur ) {
                ++$pos if $total_diff->[$x][0] ne '-';
                ++$neg if $total_diff->[$x][0] eq '-';
                ++$x;
            }
            $new->[-1] = [splice @$total_diff,0,$pos+$neg];
        }
    }
    return $new;
}

sub _merge_old_lines {
    my ($total_diff, $count) = @_;
    my $new = [];

    foreach my $cur ( @$count ) {
        if ($cur > 0) {
            push @$new, [];
            my ($pos,$neg,$x) = (0)x3;
            while ( $pos < $cur ) {
                ++$pos if $total_diff->[$x][0] ne '-';
                ++$neg if $total_diff->[$x][0] eq '-';
                ++$x
            }
            $new->[-1] = [splice (@$total_diff,0,$pos+$neg)];
        }
    }
    return $new;
}

#########
# Output

sub _format {
    my ($diff,$highlight,$sep) = @_;
    my $output;
    foreach my $hunk (@$diff) {

        $output .= "\n$sep->[0]\n";
        foreach my $sect (@$hunk) {
            if ($sect->[0] eq ' ') {
                $output .= "$sect->[1] ";
            }
            elsif ($sect->[0] eq '+') {
                $output .= " $highlight->{plus}$sect->[1]$highlight->{end} ";
            }
            else {
                $output .= " $highlight->{minus}$sect->[1]$highlight->{end} ";
            }
        }
        $output .= "\n$sep->[1]\n";
    }
    return $output;
}

sub html_header {
    my ($old,$new,$opt) = @_;

    my $old_time = strftime( "%A, %B %d, %Y @ %H:%:%S",
                            (ref $old) ? time : (stat $old)[9]
                            , 0, 0, 0, 0, 70, 0 );
    my $new_time = strftime( "%A, %B %d, %Y @ %H:%:%S",
                            (ref $new) ? time : (stat $new)[9]
                            , 0, 0, 0, 0, 70, 0 );

    $old = (!ref $old) ? $old : "old";
    $new = (!ref $new) ? $new : "new";

    if ($opt->{plain}) {
        return "<html><head><title>Difference of $old, $new</title></head><body>"
    }

    my $header = (exists $opt->{header}) ? $opt->{header} : qq(
        <div>
        <font size="+2"><b>Difference of:</b></font>
        <table border="0" cellspacing="5">
        <tr><td class="minus">---</td><td class="minus"><b>$old</b></td><td>$old_time</td></tr>
        <tr><td class="plus" >+++</td><td class="plus" ><b>$new</b></td><td>$new_time</td></tr>
        </table></div>
    );

    my $script = ($opt->{functionality}) ? "" : qq(
        <script>
        toggle_plus_status = 1;
        toggle_minus_status = 1;
        function dis_plus() {
            for(i=0; (a = document.getElementsByTagName("span")[i]); i++) {
                if(a.className == "plus") {
                    a.style.display="none";
                }
            }
        }
        function dis_minus() {
            for(i=0; (a = document.getElementsByTagName("span")[i]); i++) {
                if(a.className == "minus") {
                    a.style.display="none";
                }
            }
        }
        function view_plus() {
            for(i=0; (a = document.getElementsByTagName("span")[i]); i++) {
                if(a.className == "plus") {
                    a.style.display="inline";
                }
            }
        }
        function view_minus() {
            for(i=0; (a = document.getElementsByTagName("span")[i]); i++) {
                if(a.className == "minus") {
                    a.style.display="inline";
                }
            }
        }

        function toggle_plus() {
            if (toggle_plus_status == 1) {
                dis_plus();
                toggle_plus_status = 0;
            }
            else {
                view_plus();
                toggle_plus_status = 1;
            }
        }

        function toggle_minus() {
            if (toggle_minus_status == 1) {
                dis_minus();
                toggle_minus_status = 0;
            }
            else {
                view_minus();
                toggle_minus_status = 1;
            }
        }
        </script>
    );

    my $style = (exists $opt->{style}) ? $opt->{style} : qq(
        <style>
            .plus{background-color:#00BBBB; visibility="visible"}
            .minus{background-color:#FF9999; visibility="visible"}
            DIV{ margin:50px; border:solid; background-color:#F2F2F2; padding:5px; }
            BODY{line-height:1.7; background-color:#888888}
            B{font-size:bigger;}
            .togglep {
                font-size : 12px;
                font-family : geneva, arial, sans-serif;
                color : #ffc;
                background-color : #00BBBB;
            }
            .togglem {
                font-size : 12px;
                font-family : geneva, arial, sans-serif;
                color : #ffc;
                background-color : #ff9999;
            }
        </style>
    );

    my $functionality = ($opt->{functionality}) ? "" : qq(
        <div>
        <form>
        <table border="0" cellspacing="5">
        <td><input type="button" class="togglep" value="Toggle Plus" onclick="toggle_plus(); return false;" /></td><td width="10">&nbsp;</td>
        <td><input type="button" class="togglem" value="Toggle Minus" onclick="toggle_minus(); return false;" /></td><td width="10">&nbsp;</td>
        </table>
        </form>
        </div>
    );

    return qq(
        <!DOCTYPE html
            PUBLIC "-//W3C//DTD XHMTL 1.0 Transitional//EN"
            "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
        <html><head>
        <title>Difference of $old, $new</title>
        $script
        $style
        </head><body>
        $header
        $functionality
        <div>
    );
}

sub html_footer {
    if ((@_ == 3) && (exists $_[2]->{footer})) {
        return $_[2]->{footer}
    }
    return "</div></body></html>"
}

1;

__END__

=pod

=head1 NAME

Text::ParagraphDiff - Visual Difference for paragraphed text.

=head1 ABSTRACT

C<Text::ParagraphDiff> finds the difference between two paragraphed text files by word
rather than by line, reflows the text together, and then outputs result as xhtml.

=head1 SYNOPSIS

    use Text::ParagraphDiff;
    print text_diff('old.txt','new.txt');  # old.txt and new.txt are filenames
    print text_diff(\@old,\@new);          # Or pass array references
    print text_diff($old,$new,{plain=>1}); # Pass options (see below)

    # or use the premade script:
    # ./tdiff.pl oldfile newfile

=head1 DESCRIPTION

C<Text::ParagraphDiff> is a reimplementation of C<diff> that is meant for
paragraphed text rather than for code.  Instead of "diffing" a document by
line, C<Text::ParagraphDiff> expands a document to one word per line, uses
C<Algorithm::Diff> to find the difference, and then reflows the text back
together, highlighting the "add" and "subtract" sections.  Writers and editors
might find this useful for sending revisions to each other across the internet;
a single user might use it to keep track of personal work.  For example output,
please see diff.html in the distribution, as well as the sources for the
difference, old.txt and new.txt.

The output is in xhtml, for ease of generation, ease of access, and ease of
viewing.  C<Text::ParagraphDiff> also takes advantage of two advanced features
of the median: CSS and JavaScript.

CSS is used to cut down on output size and to make the output very pleasing to
the eye.  JavaScript is used to implement additional functionality: two buttons
that can toggle the display of the difference.  CSS and JavaScript can be
turned off; see the C<plain> option below. (Note: CSS & Javascript tested with
ozilla 1.0 and IE 5.x)

=head1 OPTIONS

Options are stored in a hashref, C<$opt>.  C<$opt> is an optional last argument
to C<text_diff>, passed like this:

    text_diff($old, $new, {plain => 1,
                           escape => 1,
                           functionality => 1,
                           style => 'stylesheet_code_here',
                           header => 'header_markup_here'});

Options are:

=over 3

=item B<plain>

When set to a true value, C<plain> will cause a document to be rendered
plainly, with very sparse html that should be valid even through Netscape
Navigator 2.0.

=item B<functionality>

When set to a true value, C<functionality> will cause the JavaScript toggle
buttons to not be shown.

=item B<style>

When C<style> is set, its value will override the default stylesheet.  Please
see C<output_html_header> above for the default stylesheet specifications.

=item B<header>

When C<header> is set, its value will override the default difference header.
Please see C<output_html_header> above for more details.

=item B<header>

When C<header> is set, its value will override the default difference header.
Please see C<output_html_header> above for more details.

=item B<escape>

When C<escape> is set, then output will not be escaped.  Useful if you want to
include your own markup.

=item B<sep>

When C<sep> is set, its value will override the default paragraph
separator.  C<sep> should be a reference to an array of 2 elements;
the starting paragraph separator, and the ending separator.  The default
value is C<['<p>',</p>']>.

=item B<minus_first>

By default, when there is a +/- pair, + items appear first by default.
However, if C<minus_first> is set to a true value, then the order will
be reversed.

=back

=head1 EXPORT

C<text_diff> is exported by default.
Additionally, C<create_diff>, C<html_header>, and C<html_footer> are optionally
exported by request (e.g. use C<< Text::ParagraphDiff qw(create_diff)) >>.
C<create_diff> is the actual diff itself; C<html_header> and C<html_footer>
should be obvious.

=head1 BUGS

In some situations, deletion of entire paragraphs in special places might make
the surrounding line-breaks become whacky.  If you can isolate the case, please
send me a bug report, I might be able to fix it.  In the mean time, if this
happens to you, just fix the output's markup by hand, it shouldn't be too
complicated.

=head1 AUTHOR

Joseph F. Ryan (ryan.311@osu.edu)

=head1 SEE ALSO

C<Algorithm::Diff>.

=cut
