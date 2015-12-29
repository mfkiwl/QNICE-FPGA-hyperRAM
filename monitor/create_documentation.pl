#
# Simple Perl program to generate a monitor function documentation using pdflatex.
# This should be executed every time something is changed on the monitor.
#
# 29-DEC-2015, B. Ulmann.
#

use strict;
use warnings;

use Data::Dumper;

my $prefix = 'doc'; # All files generated by this program will start with this prefix and most of them will be deleted at the end.
open my $latex, '>', "$prefix.tex" or die "Could not write $prefix.tex: $!\n";
print $latex "\\documentclass{report}
\\title{QNICE monitor function documentation}
\\author{Auto generated}
\\begin{document}
\\maketitle
";

my %description;
for my $filename (glob('*.asm'))
{
    print "Processing $filename...\n";

    my $data;
    {
        local $/;
        open my $handle, '<', $filename or die "Could not open $filename for read: $!\n";
        $data = <$handle>;
        close $handle;
    }

    while ($data =~ /;\*\*\**(.+?);\*\*\**/smg)
    {
        my $text = $1;
        my ($group, $function) = $text =~ /(\w+)\$(\w+)/;
        next if !defined($group) or !defined($function);

        $text =~ s/^;\**\s+//smg;
        $text =~ s/\n/\~\\\\\n/smg; # Just in case we have an empty line, prefix the linebreak with a tilde for LaTeX. :-)
        $description{$group}{$function} = $text;
    }
}

for my $group (sort(keys(%description)))
{
    $group =~ s/_/\\_/g;
    $group =~ s/\$/\\\$/g;
    print $latex "\\chapter{$group}\n";
    my $functions = $description{$group};
    for my $function (sort(keys(%$functions)))
    {
        my $text = $functions->{$function};
        $function =~ s/_/\\_/g;
        $function =~ s/\$/\\\$/g;

        $text =~ s/_/\\_/g;
        $text =~ s/\$/\\\$/g;
        print $latex " \\section{$group\\\$$function}\n$text\n";
    }
}

print $latex "\\end{document}\n";
close $latex;

system("pdflatex $prefix");
system("rm $prefix.aux");
system("rm $prefix.log");
system("rm $prefix.tex");
system("mv $prefix.pdf ../doc/monitor/");
