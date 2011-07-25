#!/usr/bin/perl -w

use Data::Dumper;
use DBI;

use strict;
use warnings;


my $dir = "./menus";

#==DB SETUP==
#open connection to db
my $dbh = DBI->connect('DBI:mysql:foodie', 'foodie', 'foodie82')
    or die "Couldn't connect to database: " . DBI->errstr;

#=max ID;
my $file_id;
my $sql_rest = "SELECT rest_id FROM restaurants";
my $select_rest = $dbh->prepare($sql_rest) or die "Error preparing query sql_rest\n";
#execute
my $chk = $select_rest->execute();

my @rest_results;
my $rest_id;
while ($rest_id = $select_rest->fetchrow_array()) {
    push(@rest_results, $rest_id);
}

#finish
$select_rest->finish;

$dbh->disconnect;

#BATCH
foreach my $f (@rest_results) {
    print "Importing Menu $f\n";
    `perl import_menus_db.pl $dir/$f`;
}

#ERROR LOG
#56964 - menu missing
#3462 - malformed xml menu: should remove
#60672 - menu element is missing price (Creamsicle), rest of import is ok no data loss



