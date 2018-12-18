#!/usr/bin/env perl6


use lib <lib>;
use Z::Cipher::File;

my $filename = 'cipher/z340'.IO;

my $cipher-file = Z::Cipher::File.new();

$cipher-file.parse(:$filename);
.say for $cipher-file.sym-grid;
