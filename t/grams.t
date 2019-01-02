#!/usr/bin/env perl6

#use Test;

enum GRAM (
  UNI   => 1,
	BI    => 2,
	TRI   => 3,
	QUAD  => 4,
	QUINT => 5,
);

my $file = 'cipher/z340';

multi gram (UNI $g) {
	my $b =  0;                 # back step 
	my @sym =  $file.IO.comb(/\N/);
  my $bag = @sym.rotor($g => $b).map(*.join).Bag;

	#.say for $bag.pairs;
	my $gram = gather for $bag.pairs {
		.take;
	}
  $gram;

}

multi gram (GRAM $g) {
	my $b = $g - ($g + $g - 1);                 # back step 
	my @sym =  $file.IO.comb(/\N/);
  my $bag = @sym.rotor($g => $b).map(*.join).Bag;

	#.say for $bag.pairs;
	my $gram = gather for $bag.pairs {
		.take if .value > 1;
	}
  $gram;

}

my @sym =  $file.IO.comb(/\N/);

my $grams =  gram(BI);
say $grams[0];

say @sym.join.indices: $grams[0].key;
say @sym[212];




