use Z::Cipher;

unit module Z::Util;

enum ARROWS is export (
  UP    => 82,
  DOWN  => 81,
  LEFT  => 80,
  RIGHT => 79,
);

multi grid-pairs (Z::Cipher :$cipher) is export {
  my @pairs;
  
	for ^$cipher.row-count X ^$cipher.col-count -> ($r, $c) {
		my $sym = $cipher.sym[$r][$c];
    my $pair =  [$c, $r, $sym.w, $sym.h] => $sym;

		push @pairs, $pair;
    
	}
	return @pairs;
}

