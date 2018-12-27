
unit class Z::Cipher::File;


method parse (:$filename --> Array) {
  my @sym;
  my $file = slurp $filename;
  return Nil unless [==] (.chars for $file.lines);

  @sym.append: .comb for $file.lines;
	say @sym;
	return @sym;

}
