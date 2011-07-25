#Menu_Parser.pm

#===DOCUMENTATION===

=head1 NAME

Menu_Parser.pm

=head1 SYNOPSIS

Menu_Parser.pm contains a Parse() runtime, and several hooks for a SAX Parser (XML::PerlSAX implementation.) Using each downloaded menu,
the data is parsed, and respective elemenets are imported into a mysql database accordingly.

=head1 DESCRIPTION

Menu_Parser Parse() subroutine takes a menu and parses the XML, located specific elements of interest (food name, price, description, etc.)
and send it to a mysql database.  Several global variables are maintained to deal with nested XML elements and to record the order of elements
in the parse tree.  Additionally, HTML specific entities are removed and the string cleaned.

=head1 METHODS

=head2 Parse

Parse provides the main runtime for the Menu_Parser, and is the only method that should be called directly.  Parse takes a single argument,
the menu id, and proceeds to run the SAX parser on the menu's elements.

=head2 new

initializes the handler for the SAX Parser

=head2 start_element

start_element: handle a start-of-element event: output start tag and attributes

=head2 end_element

end_element: handle an end-of-element event:
output end tag UNLESS it's from a <literal> inside a <programlisting>

=head2 clean

clean: provides whitespace removal

=head2 checkDB

checkDB: returns any error message from inserting into db

=head2 characters

characters: handle a character data event

=head2 comment

comment: handle a comment event: turn into a <comment> element

=head2 processing_instruction

processing_instruction: handle a PI event: delete it

=head2 entity_reference

entity_reference: handle internal entity reference (we don't want them resolved)

=head2 stack_top

stack_top: provides peek on what's top of the stack

=head2 stack_contains

stack_contains: takes a look at internals of stack

=head2 output

output: prints string


=cut

#===END DOCUMENTATION===

package Menu_Parser;

use Data::Dumper;
use DBI;
use HTML::Entities;
use HTML::Strip;

use strict;
use warnings;
use XML::Parser::PerlSAX;

#
# global variables
#
#STACKS
my @element_stack;                # remembers element names

my $in_intset;                    # flag: are we in the internal subset?

my @tag_stack;

my @menu_stack;
my @menu_desc_stack;

my @item_stack;

my @option_group_stack;

my @option_stack;

###
### Document Handler Package
### WE want access to globals so we'll not separate the package
###

my $item_id;
my $hs;
my $rest_id;



=head2 Parse

Parse: the main subroutine to be called in order to parse a menu
will determine the item_id by looking at the maximum id already
in the database.
=cut
# --------------------------------------------------------------
# Parses a menu, calling the sax parser
# --------------------------------------------------------------
sub Parse {

    #my $rest_id = $ARGV[0];
    $rest_id = shift;
    $rest_id =~ s/\D+//g;

    my $parser = XML::Parser::PerlSAX->new( Handler => Menu_Parser->new( ) );

#==DB SETUP==
#open connection to db
    my $dbh = DBI->connect('DBI:mysql:foodie', 'foodie', 'foodie82')
    or die "Couldn't connect to database: " . DBI->errstr;

#=max ID;
    #my $item_id;
    my $sql_max = "SELECT MAX(food_items.item_id) FROM food_items";
    my $select_max = $dbh->prepare($sql_max) or die "Error preparing query sql_max\n";

#execute
    my $maxv = $select_max->execute();
    my @item_num = $select_max->fetchrow_array();
    $item_id = $item_num[0];

#finish
    $select_max->finish;
    if (not defined $item_id) {
	$item_id=1;
    }

#SQL INSERT
#build query string
    my $sql = "INSERT INTO food_items VALUES( ?, ?, ?, ?, ?)";
    my $sql_cat = "INSERT INTO categories VALUES(?, ?, ?)";
#prepare statement w/ placeholders
    my $insert = $dbh->prepare($sql) or die "Error preparing query\n";
    my $insert_cat = $dbh->prepare($sql_cat) or die "Error preparing query sql_cat\n";


#SQL INSERT (OPTIONS)
#build query string
    my $sql_options = "INSERT INTO food_options VALUES(?, ?, ?, ?)";
#prepare statement w/ placeholders
    my $insert_options = $dbh->prepare($sql_options) or die "Error preparing query sql_options\n";


#HTML STripper
    #my $hs = HTML::Strip->new();
    $hs = HTML::Strip->new();

#PARSING EXEC
    if( my $file = shift @ARGV ) {
	$parser->parse( Source => {SystemId => $file} );
    } else {
	my $input = "";
	while( <STDIN> ) { $input .= $_; }
	$parser->parse( Source => {String => $input} );
    }

#close DB
    $dbh->disconnect;

    print "DONE\n";
    exit;
}



=head2 new

new: initializes the handler for the SAX Parser
=cut
# --------------------------------------------------------------
# initialize the handler package
# --------------------#
sub new {
    my $type = shift;
    return bless {}, $type;
}

=head2 start_element

start_element: handle a start-of-element event: output start tag and attributes

=cut
# --------------------------------------------------------------
# handle a start-of-element event: output start tag and attributes
# --------------------
sub start_element {
    my( $self, $properties ) = @_;
    # note: the hash %{$properties} will lose attribute order

    # close internal subset if still open
    output( "]>\n" ) if( $in_intset );
    $in_intset = 0;

    # remember the name by pushing onto the stack
    push( @element_stack, $properties->{'Name'} );

    #ATTRIBUTE per tag (INFO)
    my %attributes = %{$properties->{'Attributes'}};
    push(@tag_stack, {%attributes});


    #==ACTION CASES==

    #MENU
    if(defined $attributes{"type"} && $attributes{"type"} eq "menu") {

        #NAME
        push(@menu_stack, $attributes{"name"});

        #DESCRIPTION (often optional arg)
        if (defined $attributes{"description"}) {
            push(@menu_desc_stack, $attributes{"description"});
        }
        else {
            push(@menu_desc_stack, "");
        }

    }
    #ITEM
    if(defined $attributes{"type"} && $attributes{"type"} eq "item") {
        push(@item_stack, {%attributes});
        ++$item_id;
    }

    #OPT GROUP
    if(defined $attributes{"type"} && $attributes{"type"} eq "option group") {
        push(@option_group_stack, {%attributes});
    }

    #OPTION
    if(defined $attributes{"type"} && $attributes{"type"} eq "option") {
        push(@option_stack, {%attributes});
    }

}


=head2 end_element

end_element: handle an end-of-element event: 
output end tag UNLESS it's from a <literal> inside a <programlisting>

=cut
# --------------------------------------------------------------
# handle an end-of-element event: output end tag UNLESS it's from a
# <literal> inside a <programlisting>
# --------------------
sub end_element {
    my( $self, $properties ) = @_;

    #TAGS
    my %tag = %{pop(@tag_stack)};

    #MENU
    if(defined $tag{"type"} && $tag{"type"} eq "menu") {
        pop(@menu_stack);
        pop(@menu_desc_stack);
    }

    #ITEM
    if(defined $tag{"type"} && $tag{"type"} eq "item") {
        my $item_attr = pop(@item_stack);

        #print "@menu_stack : ";
        #print "$item_id : $rest_id :  $item_attr->{name} ";
        #print "@menu_desc_stack";

        #BUILD VARS
        my $name = $item_attr->{name};
        my $description = "";
        if(defined $item_attr->{description}) {
            $description = $item_attr->{description};
        }
        my $price;
        if(defined $item_attr->{price}) {
            $price = $item_attr->{price};
        }
        elsif (defined $item_attr->{price_range_low}) {
            $price = $item_attr->{price_range_low};
        }
        else {
            $price = $item_attr->{price_range_high};
        }


        #build category string
        #we'll use --- as a delimiter
        my $menu_str = "";
        foreach my $m (@menu_stack) {
            if ($m ne "") {
                $menu_str .= $m;
            }
            if ($m ne "" && $m ne $menu_stack[-1]) {
                $menu_str .= "---";
            }
        }

        my $menu_desc_str = "";
        foreach my $m (@menu_desc_stack) {
            if ($m ne "") {
                $menu_desc_str .= $m;
            }
            if ($m ne "" && $m ne $menu_desc_stack[-1]) {
                $menu_desc_str .= "---";
            }
        }

        #print "$menu_str : $menu_desc_str : $opt_str : $opt_group_str\n";
        #SQL PREPARE HERE

        #clean HTML string
        $item_id = HTML::Entities::decode_entities($item_id);
        $rest_id =  HTML::Entities::decode_entities($rest_id);

        $name = $hs->parse(clean(HTML::Entities::decode_entities($name)));
        $hs->eof;

        $description = $hs->parse(HTML::Entities::decode_entities($description));
        $hs->eof;

        $price = HTML::Entities::decode_entities($price);

        $menu_str = $hs->parse(HTML::Entities::decode_entities($menu_str));
        $hs->eof;

        $menu_desc_str = $hs->parse(HTML::Entities::decode_entities($menu_desc_str));
        $hs->eof;

        #execute
        my $rv = $insert->execute($item_id, $rest_id, $name, $description, $price);
        checkDB($rv, $item_id, "item");
        $rv = $insert_cat->execute($item_id, $menu_str, $menu_desc_str);
        checkDB($rv, $item_id, "category");
    }


    #OPTION GROUP
    if(defined $tag{"type"} && $tag{"type"} eq "option group") {
        pop(@option_group_stack);
        #print "$item_stack[-1]->{name} : OPTgrp: $option_group_attr->{name}\n";
    }


    #OPTION
    if(defined $tag{"type"} && $tag{"type"} eq "option") {
        my $option_attr = pop(@option_stack);
        my $option_group_attr = $option_group_stack[-1];

        my $opt_str = clean($option_attr->{name});
        my $opt_group_str = clean($option_group_attr->{name});

        #print "$item_stack[-1]->{name} : OPTgrp: $opt_group_str OPT: $opt_str\n";

        #sql prep here

        #clean HTML
        $item_id = HTML::Entities::decode_entities($item_id);
        $opt_group_str = $hs->parse(HTML::Entities::decode_entities($opt_group_str));
        $hs->eof;

        $opt_str = $hs->parse(HTML::Entities::decode_entities($opt_str));

        #execute
        my $rv = $insert_options->execute("", $item_id, $opt_group_str, $opt_str);
        checkDB($rv, $item_id, "options");
    }

    #ENTITY tag
    pop( @element_stack );


}
=head2 clean

clean: provides whitespace removal

=cut
# --------------------------------------------------------------
#clean: provides whitespace removal
# --------------------
sub clean {
    my $str = shift;
    if (defined $str) {

        $str =~ s/^\s+//;
        $str =~ s/\s+$//;

        return $str;
    }
    return "";
}

=head2 checkDB

checkDB: returns any error message from inserting into db

=cut
# --------------------------------------------------------------
# checkDB returns any error message from inserting into db
# --------------------
sub checkDB {
    my $rv = shift;
    my $id = shift;
    my $desc = shift;

    if($rv) {
        #print "successful insert $id : $desc\n";
    }
    else {
        print "error inserting $id : $desc\n";
    }

}


=head2 characters

characters: handle a character data event

=cut
#
# handle a character data event
#
sub characters {
    my( $self, $properties ) = @_;
    # parser unfortunately resolves some character entities for us,
    # so we need to replace them with entity references again
    my $data = $properties->{'Data'};
    $data =~ s/\&/\&/;
    $data =~ s/</\&lt;/;
    $data =~ s/>/\&gt;/;

    output( $data );
}

=head2 comment

comment: handle a comment event: turn into a <comment> element

=cut
#
# handle a comment event: turn into a <comment> element
#
sub comment {
    my( $self, $properties ) = @_;
    #output( "<comment>" . $properties->{'Data'} . "</comment>" );
}


=head2 processing_instruction

processing_instruction: handle a PI event: delete it

=cut
#
# handle a PI event: delete it
#
sub processing_instruction {
  # do nothing!
}


=head2 entity_reference

entity_reference: handle internal entity reference (we don't want them resolved)

=cut
#
# handle internal entity reference (we don't want them resolved)
#
sub entity_reference {
    my( $self, $properties ) = @_;
    output( "&" . $properties->{'Name'} . ";" );
}

=head2 stack_top

stack_top: provides peek on what's top of the stack

=cut
# --------------------------------------------------------------
# stack_top: provides peek on what's top of the stack
# --------------------
sub stack_top {
    my $guess = shift;
    my @stack = shift;
    return $stack[ $#stack ] eq $guess;
}


=head2 stack_contains

stack_contains: takes a look at internals of stack

=cut
# --------------------------------------------------------------
#stack_contains: takes a look at internals of stack
# --------------------
sub stack_contains {
    my $guess = shift;
    my @stack = shift;

    foreach( @stack ) {
        return 1 if( $_ eq $guess );
    }
    return 0;
}


=head2 output

output: prints string

=cut
# --------------------------------------------------------------
#output: prints string
# --------------------
sub output {
    my $string = shift;
    print $string;
}


1;
