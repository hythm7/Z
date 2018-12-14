#!/usr/bin/env perl6

use lib <lib>;
use Z;

my $z = Z.new();

my @sym = <a b c d e f g h i j k m n o p q r s t u v w x y z>;

my @cipher = $z.gen-cipher-from-sym(:x(17), :y(20), :sym(@sym));

say @cipher;

#$z.run();


