#! /usr/bin/perl
# fuer Perlcode:
# perl -ne 'print "#: stdin:${.}\nmsgid \"$3\"\nmsgstr \"\"\n\n" if (/\$(Schulkonsole::Common::)?_d->get\((.)(.*?)\2\)/ and $3)' start Schulkonsole/Common.pm logout
# oder: xgettext --lang=Perl --keyword=get

use File::Basename;

my $file;
foreach $file (@ARGV) {
    my ($src,$path,$suffix) = fileparse($file);
    if($suffix) {
        convert($file,$path.'/'.$src.'.tt');
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
        print(OUTF,"$line\n");
    }
    
    print " OK\n";
}

sub substitute {
    my $line = shift;
    
    return $line;
}
