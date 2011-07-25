#!/usr/bin/perl -w
use XML::Simple;
use Data::Dumper;
use URI::URL;

use lib "lib";
use Util;
use Crawl;

#use strict;
#use warnings;

#=============================
#DESCRIPTION
#given a list of zipcodes,
#will ping delivery.com website with properly generated API string
#and download a list of restaurants for that zipcode into ./restaurants
#=============================


#=============================
#REFERENCES
#http://search.cpan.org/~rse/lcwa-1.0.0/lib/lwp/lib/URI/URL.pm
#http://search.cpan.org/~szbalint/WWW-Curl-4.15/lib/WWW/Curl.pm
#=============================

#=============================
#PARAMETERS
#============================

#API Key:
my $key = "AvIaw6S6iUaKvWs44AOZhHwGD79u6E1a2DCLrIy7K305";

#output directory
my $output_dir = "./restaurants";
if (not -d "$output_dir") {
    mkdir("$output_dir", 0777) or die $!;
}
#xml file
my $file = "zipcodes.xml";

Crawl::download_restaurants($key, $output_dir, $file);


print "Done\n";
