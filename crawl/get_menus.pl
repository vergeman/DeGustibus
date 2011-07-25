#!/usr/bin/perl -w
use XML::Simple;
use Data::Dumper;
use URI::URL;

use lib "lib";
use Util;
use Crawl;

use strict;
use warnings;

#=============================
#DESCRIPTION
#foreach zipcode file that contains restaurant ids,
#grabs the menu for that restaurant id
#and augments the queue of restaurants (rewrites the file)
#=============================


#=============================
#PARAMETERS
#============================

#API Key:
#INSERT YOUR KEY HERE!
my $key = "

my $input_dir = "./menu_queue";
my $output_dir = "./menus";


Crawl::download_menus($key, $input_dir, $output_dir);


print "DONE\n";
