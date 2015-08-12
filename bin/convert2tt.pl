#! /usr/bin/perl
# fuer Perlcode:
# perl -ne 'print "#: stdin:${.}\nmsgid \"$3\"\nmsgstr \"\"\n\n" if (/\$(Schulkonsole::Common::)?_d->get\((.)(.*?)\2\)/ and $3)' start Schulkonsole/Common.pm logout
# oder: xgettext --lang=Perl --keyword=get

use File::Basename;

my $file;
foreach $file (@ARGV) {
    my @parts = split(/\./,$file);
    print "$parts[0]  - $parts[1]\n";
    if($parts[1]) {
        convert($file,$parts[0].'.tt');
    } else {
        convert($file,$file.'.tt');
    }
}



sub convert {
    my $inf = shift;
    my $outf = shift;
    
    print "   convert $inf -> $outf ...";
    open(INF,"<$inf");
    
    open(OUTF,">$outf");
    
    my $line;
    while(<INF>) {
        ($line) = $_ =~ /^(.*?)$/;
        $line = substitute($line);
        print OUTF "$line\n";
    }
    
    print " OK\n";
}

sub substitute {
    my $line = shift;
    $line =~ s/<!--#include file="(.*?)" -->/[% INCLUDE $1 %]/g;
    $line =~ s/<!--#echo var="([^\{]*?)" -->/[% $1 %]/g;
    $line =~ s/<!--#echo var="([^\{]*?)\{(.*?)\}" -->/[% $1.$2 %]/g;
    $line =~ s/<gettext>(.*?)<\/gettext>/[% d.get('$1') %]/g;
    $line =~ s/<gettext>/[% d.get('/g;
    $line =~ s/<\/gettext>/') %]/g;
    $line =~ s/<!--#if expr="\$loop_(.*?)" -->/[% FOREACH $1 %]/g;
    $line =~ s/<!--#if expr="\$(.*?)" -->/[% IF $1 %]/g;
    $line =~ s/<!--#else -->/[% ELSE %]/g;
    $line =~ s/<!--#endif -->/[% END %]/g;
    $line =~ s/<!--#set var="(.*?)" value="(.*?)" -->/[% $1=$2 %]/g;
    $line =~ s/\$\{(.*?)\{(.*?)\}\}([a-zA-Z0-9_]*?)/[% $1.$2 %]$3/g;
    $line =~ s/\$([^\{]*?)\{(.*?)\}/[% $1.$2 %]/g;
    $line =~ s/"\$(.*?)"/"[% $1 %]"/g;
    $line =~ s/\.shtml\.inc/.inc.tt/g;
    $line =~ s/\.shtml/.tt/g;
    return $line;
}
