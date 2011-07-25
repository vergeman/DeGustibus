#!/usr/bin/perl -w


use strict;
use warnings;

#my @zips = ('10027', '11104', '10017', '10036');
my @zips = ('10027', '10025');

#foreach my $z (@zips) {
#    print "building term_doc index for $z\n";
#    `perl build_term_doc_matrix2.pl $z`
#}

print "building term_doc index for @zips\n";
`perl build_term_doc_matrix2.pl @zips`
