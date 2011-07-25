#DataFilter.pm

#===DOCUMENTATION===

=head1 NAME

DataFilter.pm

=head1 SYNOPSIS

    DataFilter.pm contains subroutines to import and prepare crawled restaurant and menu data from delivery.com into a mysql
database.  Database information is l: foodie, p: foodie82.

=head1 DESCRIPTION

DataFilter.pm provides several steps necessary to formatting, parsing and preparing data for eventual storage in a mysql
database. 

=head1 METHODS

=head2 restaurant_import

restaurant_import takes the list of restaurants, parses the data and imports it into the "restaurants" table in the "foodie"
database.  This is strictly for restaurant data, whose id's will be used in subsequent table references.

=head2 clean_items

restaurant items typically have a number of beverages.  Clean items takes a list of beverage related keywords and removes
their entires from the database.

=head2 build_term_doc

build_term_doc creates a term document matrix, given an input of zipcodes.  The Foodie database is queried, and all resulting
items in those restaurants are returned.  Terms for each of these items are decomposed and added to an interal term-document matrix
which is then exported in the ./index subdirectory.  The file name is given as the first zipcode argument (though the contents may
include multiple zipcodes.)  This data will be directly read by the clustering engine, and represents the final step in the data
processing.

=cut

#===END DOCUMENTATION===

package DataFilter;

use XML::Simple;
use Data::Dumper;
use DBI;

use lib "lib";
use Util;

use strict;
use warnings;


=head2 restaurant_import

restaurant_import:  performs a simple xml parse of restaurant data, imports it into the foodie database.

=cut
# --------------------------------------------------------------
# populates (only) restaurant information in to a mysql database
# --------------------------------------------------------------
sub restaurant_import {
    my $input_dir = shift;

    #get files
    my @files = Util::getFilesDir($input_dir);

    my $xml = XML::Simple->new();

    #open connection to db
    my $dbh = DBI->connect('DBI:mysql:foodie', 'foodie', 'foodie82')
    or die "Couldn't connect to database: " . DBI->errstr;


#==IMPORT DATA==
    #foreach zipcode list of restaurants
    foreach my $f (@files) {

	my $data = $xml->XMLin("$input_dir/$f");
	#print Dumper $data;
	my @restaurants = keys %{$data->{'restaurants'}->{'restaurant'}};

	#build query string
	my $sql = "INSERT INTO restaurants VALUES( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

	#prepare statement w/ placeholders
	my $insert = $dbh->prepare($sql) or die "Error preparing query\n";

	#for each restaurant
	foreach my $r (@restaurants) {

        #get values
	    my $id = $data->{'restaurants'}->{'restaurant'}->{$r}->{'id'};
	    my $latitude = Util::Get($data->{'restaurants'}->{'restaurant'}->{$r}->{'latitude'});
	    my $longitude = Util::Get($data->{'restaurants'}->{'restaurant'}->{$r}->{'longitude'});
	    my $name = Util::Get($r);

	    my $cuisines = Util::Get($data->{'restaurants'}->{'restaurant'}->{$r}->{'cuisines'});

	    my $type = Util::Get($data->{'restaurants'}->{'restaurant'}->{$r}->{'type'});
	    my $minimum = Util::Get($data->{'restaurants'}->{'restaurant'}->{$r}->{'minimum'});
	    my $payments_accepted = Util::Get($data->{'restaurants'}->{'restaurant'}->{$r}->{'payments_accepted'});
	    my $overall_rating = Util::Get($data->{'restaurants'}->{'restaurant'}->{$r}->{'overall_rating'});
	    my $description = Util::Get($data->{'restaurants'}->{'restaurant'}->{$r}->{'description'});

	    my $zipcode = $f;
	    $zipcode =~ s/(\d+).*/$1/g;

	    #execute
	    #my $rv;
	    my $rv = $insert->execute($id, $latitude, $longitude, $zipcode, $name, $cuisines, $type, $minimum, $payments_accepted, $overall_rating, $description);

	    #test output
	    if ($rv) {
		print "successful insert $id\n";
	    }
	    else {
		print "error inserting $id $name\n";
	    }

	}

    #print Dumper $data;
    }

    #close DB
    $dbh->disconnect;
}


=head2 clean_items

clean_items: given a list of items, will search for approximate matches %LIKE% or exact matches LIKE
in the database and removes their listings.

=cut
# --------------------------------------------------------------
# deletes items with specified keywords in db
# --------------------------------------------------------------
sub clean_items {


    my $dbh = DBI->connect('DBI:mysql:foodie', 'foodie', 'foodie82')
	or die "Couldn't connect to database: " . DBI->errstr;

    #item name filters
    my @filters = ("cola", "coke", "coffee", "yohoo", "yoohoo", "soda", "espresso", "starbucks", "milk",
		   "bottled water", "side", "hot chocolate", "frappe", "kirin", "snapple", "iced tea",
		   "seltzer", "perrier", "beer", "stella", "pellegrino", "corona", "slush", "coors", "vitamin water",
		   "guiness", "voss", "nantucket nectar", "minute maid", "fountain drink", "pelligrino", "samuel adams",
		   "spring water", "shake", "gatorade", "asahi");
    
    my @removes = ("tea", "Mistic", "Tea (Te)", "Hot Tea", "Tsing Tao", "Brown Ale");


    my $qry_string;

    #build query string aprox filter
    while (@filters) {
	my $arg = shift @filters;
	$qry_string .= "F.name LIKE \'%" . $arg . "%\'";
	if (@filters) {
	    $qry_string .= " OR ";
	}
    }
    
    #build query string exact filter
    my $qry_rmv_string;
    while (@removes) {
	my $arg = shift @removes;
	$qry_string .= " OR F.name LIKE \'" . $arg . "\'";
	
	#if (@removes) {
	#    $qry_rmv_string .= " OR ";
	#}
    }

    #append to sql query
    my $sql = "(SELECT F.item_id FROM food_items F WHERE " . $qry_string . $qry_rmv_string . ")";
    
    print "$sql\n";

    #send it
    my $select_id = $dbh->prepare($sql) or die "Error";
    
    my $chk = $select_id->execute();

    #output

    my $delete_sql;
    my $select_id2 = $dbh->prepare($delete_sql) or die "Error";

    while (my @items = $select_id->fetchrow_array() ) {
	chomp(@items);
	print "$items[0]\n";
	
	$delete_sql = "DELETE FROM food_items WHERE food_items.item_id = $items[0]";

	$select_id2 = $dbh->prepare($delete_sql) or die "Error";

	my $chk2 = $select_id2->execute();
    }

    $select_id->finish;
    $select_id2->finish;
    $dbh->disconnect;
}



=head2 build_term_doc

build_term_doc: given a list of zipcodes, will create an internal nested hash of terms
and term frequencies.  These will be exported to a text file for later reading.

=cut
# --------------------------------------------------------------
# builds a term-doc nested hash, exports term-(doc_id: count), (doc_id). . . lines.
# --------------------------------------------------------------

sub build_term_doc {
    
    my $dbh = DBI->connect('DBI:mysql:foodie', 'foodie', 'foodie82')
    or die "Couldn't connect to database: " . DBI->errstr;


#build zipcode
    #my @args_list = @ARGV;
    my @args_list = @_;
    print @args_list;

    my $zipcode_sql = "AND (";
    while (@args_list) {
	
	my $arg = shift @args_list;
    
	$zipcode_sql .= "R.zipcode = $arg ";

	if (@args_list) {
	    $zipcode_sql .=  " OR ";
	}
    }
    $zipcode_sql .= ") ";


#GETTING DATA
    my $sql = "SELECT F.item_id, F.rest_id, R.name, F.name, F.description, R.cuisines
FROM food_items F, restaurants R
WHERE F.rest_id = R.rest_id $zipcode_sql
AND R.type = \'Restaurant\'";


    my $select_id = $dbh->prepare($sql) or die "Error preparing query sql_rest\n";

    #execute
    my $chk = $select_id->execute();
    
    #==BUILD TERM TABLE
    my $stemmer = new Stem;
    my $stop_hash = Util::loadStopWords("./lib/stopwords_long.txt");

    my %term_doc = (); #matrix

    #process results for term table
    my @items;
    my $count = 0;
    while (@items = $select_id->fetchrow_array()) {

	#each item we make to a doc vector
	chomp(@items);

	#clean text
	my $item_id = $items[0];
	my $rest_id = $items[1];
	my @rest_name = Util::clean(\$stemmer, $items[2]);
	my @item_name = Util::clean(\$stemmer, $items[3]);
	my @item_desc = Util::clean(\$stemmer, $items[4]);
	my @cuisines = Util::clean(\$stemmer, $items[5]);


	#amalgamate text
	my @terms;
	push(@terms, @rest_name, @item_name, @item_desc, @cuisines);
	#print Dumper \@terms;

	#each term in menu item
	foreach my $t (@terms) {
	    
	    if(not exists $stop_hash->{$t}) {
	    
		#exists
		if (exists $term_doc{$t}) {
		    $term_doc{$t}{'-1'}++;
		    $term_doc{$t}{$item_id}++;
		}

		#not exists
		else {
		    $term_doc{$t}{'-1'} = 1;
		    $term_doc{$t}{$item_id} = 1;
		}
		
	    }
	    
	}

	print "$item_id\n";
    }
    
    #===OUTPUT==
    #watch the spacing
    #open(FILE, ">term_doc.idx");

    #use first arg as default
    my $zipcode = $ARGV[0];
    
    open(FILE, ">./index/$zipcode.idx");

    foreach my $t (keys %term_doc) {
	
	print FILE "$t -1:$term_doc{$t}{'-1'} ";

	foreach my $d (keys %{$term_doc{$t}}) {

	    if ($d ne "-1") {
		print FILE "$d:$term_doc{$t}{$d} ";
	    }
	    
	}
	print FILE "\n";
    }

    close (FILE);


    #finish & cleanup DB
    $select_id->finish;
    $dbh->disconnect;

}



1;
