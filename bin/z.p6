#!/usr/bin/env perl6

use lib <lib>;
use Z;
use Z::Cipher;

my $filename = "cipher/z340".IO;
my $z = Z.new();

my $grid = $z.gen-grid(:$filename);
$z.set-content($grid);

$z.run();


