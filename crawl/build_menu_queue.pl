#!/usr/bin/perl -w
use XML::Simple;
use Data::Dumper;

use lib "lib";
use Util;
use Crawl;

use strict;
use warnings;



#============================
#DESCRIPTION
#given a list of files in ./restaurant
#formatted as <zip>-<address>.xml
#will output a list of restaurant ids to menu_queue directory
#for further grabbing
#============================



#============================
#PARAMETERS
#============================
my $input_dir = "./restaurants";

my $output_dir = "./menu_queue";

Crawl::queue_menus($input_dir, $output_dir);


print "DONE\n";
