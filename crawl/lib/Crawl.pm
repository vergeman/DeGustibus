#Crawl.pm

#===DOCUMENTATION===

=head1 NAME

Crawl.pm

=head1 SYNOPSIS

Crawl.pm contains subroutines to download restaurant and menu data from delivery.com.  Zipcode information
must be prepared beforehand (see zipcode.xml) to build a reference point from which data can be downloaded.

=head1 DESCRIPTION

Crawling contains several steps.  A zipcode and address must be defined, in the format according to zipcodes.xml.
download_restaurants will use these zipcodes to query delivery.com, and get a listing of available restaurants in that 
zipcode.  These restaurants will then be queued into a <zipcode>.id file via the subroutine "queue_menus."  Lastly,
with a queue of menus to be downloaded in place, the download_menus subroutine is run which will gently query delivery.com
and download the appropriate menus.

These actions need to be performed in this sequence, as each takes data from a subroutine beforehand.

=head1 METHODS

=head2 download_restaurants

Given the address and zipcodes found in zipcode.xml, download_restaurants queries delivery.com and stores the list
of available restaurants.  This is stored in a <zipcode>-<address>.xml file.

=head2 queue_menus

queue_menus takes each <zipcode>-<address>.xml file stored by download_restaurants, and parses the data for the unique
restaurant id.  These id's are stored as a list in a <zipcode>.id file.  This provides a list of menu id requests to be 
sent to the api at flexible times.

=head2 download_menus

download_menus is the last step that queries delivery.com and downloads each menu.  The menus are stored in files as their menu_id.
download_menus is set to iterate a new query every 3 minutes, with randomized sleeping to gently query delivery.com

=cut

#===END DOCUMENTATION===

package Crawl;

use XML::Simple;
use Data::Dumper;
use URI::URL;
use WWW::Curl::Easy;

use lib "lib";
use Util;

use strict;
use warnings;


=head2 download_restaurants

load_restaurants: downloads restaurant data

=cut
# --------------------------------------------------------------
# downloads restaurant data
# --------------------------------------------------------------

sub download_restaurants {
    my $key = shift;
    my $output_dir = shift;
    my $file = shift;

#example:
#https://www.delivery.com/api/api.php?key=<key>&method=delivery&street=235 Park Avenue South 5th Floor&zip=10003

    my $xs = XML::Simple->new();
    my $data = $xs->XMLin($file);

    #foreach zipcode in zipcode.xml
    foreach my $i ($data->{LOCATION} )  {

	my $count = 0;
	while (defined($i->[$count]->{ZIP})) {

	    my $zip = $i->[$count]->{ZIP};
	    my $addr = $i->[$count]->{ADDR};

	    #SKIP PREVIOUS DOWNLOADS
	    my @file_list = Util::getFilesDir($output_dir);

	    #if file already exists, don't get it again
	    my $skip = 0;
	    foreach my $f (@file_list) {
		$f =~ s/-.*.xml//g;
		if ($zip eq $f) {
		    print "Previously downloaded $f\n";
		    $skip = 1;
		}
	    }

	    if ($skip == 1) {
		$skip = 0;
		$count++;
		next;
	    }
	    #==build url==
	    my $url = "https://www.delivery.com/api/api.php?key="
		. $key .
		"&method=delivery" .
		"&street=$addr" .
		"&zip=$zip";

	    #add URL string formatting
	    $url = new URI::URL $url;

	    print "$url\n";

	    #take URL and crawl from here.
	    #want to add timing mechanism eventually so we don't bang
	    my $curl = WWW::Curl::Easy->new;

	    $curl->setopt(CURLOPT_HEADER, 0); #don't want http headers
	    $curl->setopt(CURLOPT_URL, $url);


	    #A filehandle, reference to a scalar or reference
	    #to a typeglob can be used here.
	    my $response_body;
	    $curl->setopt(CURLOPT_WRITEDATA,\$response_body);

	    #Starts the actual request
	    my $retcode = $curl->perform;

	    #Looking at the results...
	    if ($retcode == 0) {
		print("Transfer went ok\n");
		my $response_code = $curl->getinfo(CURLINFO_HTTP_CODE);
		
		#judge result and next action based on $response_code
		print("Received response: $response_body\n");

		#write to file
		open(FILE, ">", "$output_dir/$zip-$addr.xml") or die $!;
		print FILE $response_body;
		close(FILE);

	    } else {
		#Error code, type of error, error message
		print("An error happened: $retcode ".$curl->strerror($retcode)." ".$curl->errbuf."\n");
	    }

	    #pause for some random amount of time
	    sleep rand() * 10;


	    $count++;
	}

    }

}


=head2 build_menu_queue

build_menu_queue: takes restaurant data and builds a list per zipcode

=cut
# --------------------------------------------------------------
# builds a list of menus to be downloaded, in a zipcode file
# --------------------------------------------------------------

sub queue_menus {
    my $input_dir = shift;
    my $output_dir = shift;
    my $xml = XML::Simple->new();

#============================
#EXEC
#============================

#get files in directory
    my @files = Util::getFilesDir($input_dir);

#foreach file
    foreach my $f (@files) {
	my $filename = $f;
	$f =~ s/-.*.xml//g; #truncate to zipcode

	#SKIP ALREADY PROCESSED
	if (-e "$output_dir/$f.id") {
	    print "Already processed zipcode $f\n";
	    next;
	}

	#parse restaurant list file
	print "$filename\n";
	my $data = $xml->XMLin("$input_dir/$filename");

	my @ids = keys %{$data->{restaurants}->{restaurant}};


	#build array of individual restaurant ids
	my @rest_ids = ();
	foreach my $id (@ids) {
	    push(@rest_ids, $data->{restaurants}->{restaurant}->{$id}->{id})
	}


	#write to file, build zipcode filename, populated with list of restaurant ids
	open(FILE, ">", "$output_dir/$f.id");

	foreach my $id (@rest_ids) {
	    print FILE "$id\n";
	}

	close(FILE);
    }
}


=head2 download_menus

download_menus: takes menu id's from zipcode file and downloads them

=cut
# --------------------------------------------------------------
# given a directory of zipcode.id files, will query and download menus.
# --------------------------------------------------------------
sub download_menus {
    my $key = shift;
    my $input_dir = shift;
    my $output_dir = shift;


    my @zipcode_list = Util::getFilesDir($input_dir);


    foreach my $z (@zipcode_list) {
	#open a zipcode file containing ids
	open(FILE, "$input_dir/$z");
	my @ids = <FILE>;
	chomp(@ids);
	close(FILE);

	#foreach restaurant id
	my $skip = 0;
	foreach my $id (@ids) {

	    #skip if already downloaded the menu
	    my @menu_list = Util::getFilesDir($output_dir);
	    foreach my $menu (@menu_list) {
		#is an error on the server
		#56964
		#62184
		if($id eq $menu || $id eq "56964" || $id eq "62184"){
		    print "previously downloaded $id\n";
		    $skip = 1;
		}
	    }
	    
	    if ($skip == 1) {
		$skip = 0;
		next;
	    }


	    #==build url==
	    my $url = "https://www.delivery.com/api/api.php?key="
            . $key .
            "&method=menus" .
            "&mid=$id";
	    
	    #add URL string formatting
	    $url = new URI::URL $url;

	    print "$url\n";

	    #take URL and crawl from here.
	    #want to add timing mechanism eventually so we don't bang
	    my $curl = WWW::Curl::Easy->new;

	    $curl->setopt(CURLOPT_HEADER, 0); #don't want http headers
	    $curl->setopt(CURLOPT_URL, $url);

	    #A filehandle, reference to a scalar or reference
	    #to a typeglob can be used here.
	    my $response_body;
	    $curl->setopt(CURLOPT_WRITEDATA,\$response_body);

	    #Starts the actual request
	    my $retcode = $curl->perform;

	    #Looking at the results...
	    if ($retcode == 0) {
		print("Transfer went ok\n");
		my $response_code = $curl->getinfo(CURLINFO_HTTP_CODE);

		#judge result and next action based on $response_code
		print("Received response: $response_body\n");

		#write to file
		open(FILE, ">", "$output_dir/$id") or die $!;
		print FILE $response_body;
		close(FILE);

	    } else {
		#Error code, type of error, error message
		print("An error happened: $retcode ".$curl->strerror($retcode)." ".$curl->errbuf."\n");
	    }

	    my $sleep_time = rand() * 60 *3;

	    #pause seconds
	    print "pausing for $sleep_time secs . . .\n";
	    sleep $sleep_time;
	}

    }









}















1;
