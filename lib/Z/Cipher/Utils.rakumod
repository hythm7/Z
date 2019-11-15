unit module Z::Cipher::Utils;


class Gram {

  has @.gram;

}



sub gram ( :@sym!, Int:D :$gram! ) is export {

	my $back =  1 - $gram;  # back step

  gather for @sym.map( *.get-child.label ).rotor( $gram => $back ).map(*.join ).Bag.pairs {

		.take if .value > 1;

  }
}

sub grams ( :@sym!, :@grams, :$gram = 1 ) is export {

  my @result = gram :@sym, :$gram;

  return @grams unless @result;

  @grams.push: @result;

  grams :@sym, :@grams, :gram( $gram + 1 );

}

