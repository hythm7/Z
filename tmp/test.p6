#!/usr/bin/env perl6

use GTK::Simple::Button;

use lib <lib>;
use Z::Cipher::Sym;

my $s = "abcdefgh";

say $s.comb.map( -> $sym {Z::Cipher::Sym.new(label => "l") });
