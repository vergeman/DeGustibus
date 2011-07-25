#!/usr/bin/perl -w
use Data::Dumper;
use DBI;

use lib "lib";
use Util;
use DataFilter;

use strict;
use warnings;


DataFilter::clean_items();

print "DONE\n";
