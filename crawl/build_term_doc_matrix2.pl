#!/usr/bin/perl -w

use Data::Dumper;
use DBI;

use lib "lib";
use Util;
use DataFilter;

use strict;
use warnings;


# Builds a term-document matrix used for clustering
DataFilter::build_term_doc( @ARGV );






print "DONE\n";


