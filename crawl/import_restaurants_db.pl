#!/usr/bin/perl -w
use strict;
use warnings;

use XML::Simple;
use Data::Dumper;
use DBI;


use lib "lib";
use Util;
use DataFilter;


#parametrs
my $input_dir = "./restaurants";

DataFilter::restaurant_import($input_dir);

print "DONE\n";
