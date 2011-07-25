#!/usr/bin/perl -w

use lib "lib";
use Util;

use strict;
use warnings;


#==BUILD TERM TABLE
my $stemmer = new Stem;

my @query = ();
foreach my $word (@ARGV) {
    #print "$word\n";
    push(@query, Util::clean(\$stemmer, $word));

}

foreach my $w (@query) {
    print "$w ";
}
