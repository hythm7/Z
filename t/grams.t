#!/usr/bin/env perl6

use Test;

sub gram ( :@sym!, Int:D :$gram! ) is export {

  my $back =  1 - $gram;  # back step

  gather for @sym.rotor( $gram => $back ).map(*.join ).Bag.pairs {

    .take if .value > 1;

  }
}

my $cipher = q:to/END/;
abcd
abch
ijkl
mnop
qrst
uvwx
END

my @sym =  $cipher.comb(/\N/);

ok (b => 2,  c => 2,  a => 2) ~~ gram :@sym, :1gram;
ok (ab => 2, bc => 2)         ~~ gram :@sym, :2gram;



