#!/usr/bin/env perl6
use lib 'lib';

use GTK::Button;
use Z::Cipher;
use Z::Cipher::File;
use Z::Cipher::Sym;
my $filename = 'cipher/z340'.IO;

my $c = Z::Cipher.new: :$filename;
