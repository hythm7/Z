#!/usr/bin/env perl6

#use Test;

enum GRAM (
  UNI   => 1,
	BI    => 2,
	TRI   => 3,
	QUAD  => 4,
	QUINT => 5,
);

my $cipher = q:to/END/;
abcd
abch
ijkl
mnop
qrst
uvwx
END

multi gram (GRAM $g) {
	my $b = 1 - $g;                 # back step
	my @sym =  $cipher.comb(/\N/);
  my $bag = @sym.rotor($g => $b).map(*.join).Bag;

	#.say for $bag.pairs;
	my @gram = gather for $bag.pairs {
		.take if .value > 1;
	}
  @gram;

}

say gram BI;
