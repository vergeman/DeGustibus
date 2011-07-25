#package Clair::Utils::Stem;
package Stem;

use warnings;

sub new {
	my %step2list;
	my %step3list;
	my ($c, $v, $C, $V, $mgr0, $meq1, $mgr1, $_v);

   %step2list =
   ( 'ational'=>'ate', 'tional'=>'tion', 'enci'=>'ence', 'anci'=>'ance', 'izer'=>'ize', 'bli'=>'ble',
     'alli'=>'al', 'entli'=>'ent', 'eli'=>'e', 'ousli'=>'ous', 'ization'=>'ize', 'ation'=>'ate',
     'ator'=>'ate', 'alism'=>'al', 'iveness'=>'ive', 'fulness'=>'ful', 'ousness'=>'ous', 'aliti'=>'al',
     'iviti'=>'ive', 'biliti'=>'ble', 'logi'=>'log');

   %step3list =
   ('icate'=>'ic', 'ative'=>'', 'alize'=>'al', 'iciti'=>'ic', 'ical'=>'ic', 'ful'=>'', 'ness'=>'');


   $c =    "[^aeiou]";          # consonant
   $v =    "[aeiouy]";          # vowel
   $C =    "${c}[^aeiouy]*";    # consonant sequence
   $V =    "${v}[aeiou]*";      # vowel sequence

   $mgr0 = "^(${C})?${V}${C}";               # [C]VC... is m>0
   $meq1 = "^(${C})?${V}${C}(${V})?" . '$';  # [C]VC[V] is m=1
   $mgr1 = "^(${C})?${V}${C}${V}${C}";       # [C]VCVC... is m>1
   $_v   = "^(${C})?${v}";                   # vowel in stem

	my $class = shift;
	my $self = bless {
		step2list => \%step2list,
		step3list => \%step3list,
		c => $c,
		v => $v,
		cap_C => $C,
		cap_V => $V,
		mgr0 => $mgr0,
		meq1 => $meq1,
		mgr1 => $mgr1,
		un_v => $_v,
	}, $class;

	return $self;
}

sub stem {
	my $self = shift;

	my %step2list = %{ $self->{step2list} };
	my %step3list = %{ $self->{step3list} };
	my $c = $self->{c};
	my $v = $self->{v};
	my $C = $self->{cap_C};
	my $V = $self->{cap_V};
	my $mgr0 = $self->{mgr0};
	my $meq1 = $self->{meq1};
	my $mgr1 = $self->{mgr1};
	my $_v = $self->{un_v};

#  local %step2list;
#  local %step3list;
#  local ($c, $v, $C, $V, $mgr0, $meq1, $mgr1, $_v);

	my ($stem, $suffix, $firstch);
	my $w = shift;
	if (length($w) < 3) { return $w; } # length at least 3
	# now map initial y to Y so that the patterns never treat it as vowel:
	$w =~ /^./; $firstch = $&;
	if ($firstch =~ /^y/) { $w = ucfirst $w; }

	# Step 1a
	if ($w =~ /(ss|i)es$/) { $w=$`.$1; }
	elsif ($w =~ /([^s])s$/) { $w=$`.$1; }
	
	# Step 1b
	if ($w =~ /eed$/) {
		if ($` =~ /$mgr0/o) { chop($w); } 
	} elsif ($w =~ /(ed|ing)$/) {
		$stem = $`;
		if ($stem =~ /$_v/o) {
			$w = $stem;
			if ($w =~ /(at|bl|iz)$/) { $w .= "e"; }
			elsif ($w =~ /([^aeiouylsz])\1$/) { chop($w); }
			elsif ($w =~ /^${C}${v}[^aeiouwxy]$/o) { $w .= "e"; }
		}
	}

	# Step 1c
	if ($w =~ /y$/) { 
		$stem = $`; 
		if ($stem =~ /$_v/o) { $w = $stem."i"; }
	}

	# Step 2
	if ($w =~
	    /(ational|tional|enci|anci|izer|bli|alli|entli|eli|ousli|ization|ation|ator|alism|iveness|fulness|ousness|aliti|iviti|biliti|logi)$/) { 
		$stem = $`; $suffix = $1;
		if ($stem =~ /$mgr0/o) { $w = $stem . $step2list{$suffix}; }
	}

	# Step 3
	
	if ($w =~ /(icate|ative|alize|iciti|ical|ful|ness)$/) {
		$stem = $`; $suffix = $1;
		if ($stem =~ /$mgr0/o) {
			$w = $stem . $step3list{$suffix};
		}
	}

# Step 4

	if ($w =~ /(al|ance|ence|er|ic|able|ible|ant|ement|ment|ent|ou|ism|ate|iti|ous|ive|ize)$/) {
		$stem = $`; if ($stem =~ /$mgr1/o) { $w = $stem; } 
	} elsif ($w =~ /(s|t)(ion)$/) {
		$stem = $` . $1; if ($stem =~ /$mgr1/o) { $w = $stem; } 
	}


	#  Step 5
	
	if ($w =~ /e$/) {
		$stem = $`;
	  if ($stem =~ /$mgr1/o or
	      ($stem =~ /$meq1/o and not $stem =~ /^${C}${v}[^aeiouwxy]$/o)) { 
			$w = $stem;
		}
	}
	if ($w =~ /ll$/ and $w =~ /$mgr1/o) { chop($w); }
	
	# and turn initial Y back to y
	if ($firstch =~ /^y/) { $w = lcfirst $w; }
	return $w;
}

=head1 NAME

Stem - An implementation of a stemmer

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module implements a stemmer, to take one word at a time and return the stem of it.
Create a object with new, then stem a word with stem:

my $stemmer = new Stem;
my $stemmed_test = $stemmer->stem("test");
my $stemmed_testing = $stemmer->stem("testing");

=head1 METHODS

=cut

    
=head2 new

my $stemmer = new Stem;

This creates a stemmer object and initializes it so calls to stem() can be made.

=cut



=head2 stem

$stemmed_word = $stemmer->stem($word);

Returns the stemmed version of a word.

=cut



=head1 AUTHOR

Hodges, Mark << <clair at umich.edu> >>
Radev, Dragomir << <radev at umich.edu> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-clair-document at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=clairlib-dev>.
I will be notified, and then you will automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Stem

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/clairlib-dev>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/clairlib-dev>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=clairlib-dev>

=item * Search CPAN

L<http://search.cpan.org/dist/clairlib-dev>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 The University of Michigan, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
