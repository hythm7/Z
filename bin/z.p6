#!/usr/bin/env perl6

use lib <lib>;
use Z;
use Z::Cipher;

my $filename = "cipher/z340".IO;
my $z = Z.new();
$z.load-cipher(:$filename);
#$z.set-content($grid);

$z.run();


