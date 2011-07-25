#!/usr/bin/perl -w

use Data::Dumper;
use DBI;
use HTML::Entities;
use HTML::Strip;
use XML::Parser::PerlSAX;

use strict;
use warnings;

use lib "lib";
use Menu_Parser;

#=======XML NOT SO SIMPLE======
#http://docstore.mik.ua/orelly/xml/pxml/ch05_01.htm#perlxml-CHP-5-EX-2

# initialize the parser
Menu_Parser::Parse($ARGV[0]);

