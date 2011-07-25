#Util.pm

#use WWW::Curl::Easy;
#use XML::Simple;
use Data::Dumper;
#use URI::URL;

use Stem;

package Util;

use strict;
use warnings;



#==MODIFIED CLAIRLIB IMPORTS==

#Clean word
#given a string, will strip punctuation, stem and lowercase
#used in preprocessing to build index
sub clean {
    my $stemmer = shift;
    my $word = shift;

    my @words;

    #strip punctuation, split words
    my @split_words = split_words2($word, 1);
    
    #stem & lowercase
    foreach my $w (@split_words) {
	push(@words, lc ${$stemmer}->stem($w));
    }

    #lowercase
    return @words;

}

#modified split_words
#to get rid of clairlib specific character designations
#(we have original text in db)
sub split_words2 {
    my $text = shift;
    my $punc = shift;

    if( $punc ){
        $text =~ s/\^M/ /g;
	#$text =~ s/(\w)\'(\w)/$1~$2/g;
	$text =~ s/(\w)\'(\w)/$1/g;
	#additions to take out html specific characters
	#replaced w/ HTML::Entities in parsing
        #$text =~ s/\&amp;/ /g;
        #$text =~ s/quot\;/ /g;
	#$text =~ s/ltbrgt+/ /g;
	$text =~ s/[0-9]*//g;
	$text =~ s/\#//g;

	$text =~ s/[\\\/]//g;
	$text =~ s/\./ /g;
	$text =~ s/\'//g;
	$text =~ s/\,/ /g;
	$text =~ s/\?/ /g;
	$text =~ s/\!/ /g;
	$text =~ s/\;//g;
	$text =~ s/\://g;
        $text =~ s/\"//g;
        $text =~ s/\*//g;
        $text =~ s/\(//g;
        $text =~ s/\)//g;
        $text =~ s/\[//g;
        $text =~ s/\]//g;
        $text =~ s/\{//g;
        $text =~ s/\}//g;
        $text =~ s/\}//g;
        $text =~ s/\|//g;
        $text =~ s/\&//g;
        $text =~ s/\@//g;


      #$text =~ s/([',.!?;:"\*\(\)\[\]])/\ $1\ /g;
    }else{
      $text =~ s/[^A-Za-z\']/ /g;
      $text =~ s/(\w)\'(\w)/$1~$2/g;
      $text =~ s/\'/ /g;
    }
    my @words = split /\s+/, $text;

    return @words;
}



#taken from Clair::Utils::TFIDFUtils::split_words()
sub split_words {
    my $text = shift;
    my $punc = shift;

    if( $punc ){
	$text =~ s/^M/ /g;
      $text =~ s/(\w)\'(\w)/$1~$2/g;
      $text =~ s/[\\\/]//g;
      $text =~ s/\./ p_period\ /g;
      $text =~ s/\'/ p_apostrophe\ /g;
      $text =~ s/\,/ p_comma\ /g;
      $text =~ s/\?/ p_question\ /g;
      $text =~ s/\!/ p_exclamation\ /g;
      $text =~ s/\;/ p_semicolon\ /g;
      $text =~ s/\:/ p_colon\ /g;
	$text =~ s/\"/ p_dblquote\ /g;
	$text =~ s/\*/ p_star\ /g;
	$text =~ s/\(/ p_Lparen\ /g;
	$text =~ s/\)/ p_Rparen\ /g;
	$text =~ s/\[/ p_Lbracket\ /g;
	$text =~ s/\]/ p_Rbracket\ /g;
	$text =~ s/\{/ p_Lbrace\ /g;
	$text =~ s/\}/ p_Rbrace\ /g;
	$text =~ s/\}/ p_Rbrace\ /g;
	$text =~ s/\|/ p_pipe\ /g;
	$text =~ s/\&/ p_amperand\ /g;
	$text =~ s/\@/ p_at\ /g;
      #$text =~ s/([',.!?;:"\*\(\)\[\]])/\ $1\ /g;
    }else{
      $text =~ s/[^A-Za-z\']/ /g;
      $text =~ s/(\w)\'(\w)/$1~$2/g;
      $text =~ s/\'/ /g;
    }
    my @words = split /\s+/, $text;

    return @words;
}


sub Get {
    my $var = shift;
    if(defined $var) {
	return $var
    }
    return "";
}



#given a directory path,
#returns an array of the files in it
sub getFilesDir {
    my $input_dir = shift;

#get files in directory
    opendir(DIR, $input_dir) || die("Error opening directory");
    my @files = readdir(DIR);
    closedir(DIR);

#remove .. and .
    my @pruned_files = ();
    foreach my $f (@files) {
	unless ( ($f eq ".") || ($f eq "..")) {
	    push(@pruned_files, $f);
	}

    }
    return @pruned_files;
}




sub loadStopWords {
    my $filename = shift;
    my %stop_hash =();

    open FILE, "$filename"  or die ("Error opening stopwords file");    
    my @words = <FILE>;
    close(FILE);
    
    chomp(@words);

    foreach my $w (@words) {
	
	$stop_hash{$w} = 1;
    }

    return \%stop_hash;
}




1;
