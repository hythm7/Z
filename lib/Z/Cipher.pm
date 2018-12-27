use Z::Cipher::Sym;

unit class Z::Cipher;

enum DIRECTIONS is export (
  HORIZONTAL    => 'h',
  VERTICAL      => 'v',
  CLOCKWISE     => 'c',
  ANTICLOCKWISE => 'a',
);

has Int $!sym-count;
has Int $!row-count;
has Int $!col-count;

has @.sym is required;

multi method new (:@sym!, :$row-count!, :$col-count!) {
  self.bless( :@sym, :$row-count, :$col-count );
}

multi method new (IO::Path :$filename!) {
	my $file = slurp $filename;
	return Nil unless [==] (.chars for $file.lines);

	my $row-count = $file.lines.elems;
	my $col-count = $file.lines[0].chars;
	#my $sym-count = $file.chars - $row-count;
	#my $col-count = $sym-count / $row-count;

  my @sym = $file.comb: /\N/;

	@sym .= map( -> $label { Z::Cipher::Sym.new_with_label($label) });

  self.bless( :@sym, :$row-count, :$col-count );
}

submethod BUILD (
  :@sym!,
  :$row-count!,
  :$col-count!,
) {


	$!sym-count = @sym.elems; 
	$!row-count = $row-count; 
	$!col-count = $col-count; 
	@!sym = @sym;
	self.gist;
}

method gist (Z::Cipher:D:) { 
		put .map(*.label) for @!sym.rotor($!col-count);
}

method sym-count () { $!sym-count }
method row-count () { $!row-count }
method col-count () { $!col-count }

method transpose (Z::Cipher:D: --> Z::Cipher:D) {
  my @transposed;
  my @rotored = @!sym.rotor($!col-count);

	for ^$!row-count X ^$!col-count -> ($r, $c) {
    @transposed[$c][$r] = @rotored[$r][$c];
	}
	
	@transposed = gather @transposed.deepmap: *.take;

	Z::Cipher.new(:sym(@transposed), row-count => $!col-count, col-count => $!row-count);

}

multi method flip (Z::Cipher:D: HORIZONTAL --> Z::Cipher:D) {
	my @flipped;
  @flipped = @!sym.rotor($!col-count).map(*.reverse).flat;
	Z::Cipher.new(:sym(@flipped), :$!row-count, :$!col-count);
}

multi method flip (Z::Cipher:D: VERTICAL --> Z::Cipher:D) {
	my @flipped;
  @flipped = @!sym.rotor($!col-count).reverse.flat;
	Z::Cipher.new(:sym(@flipped), :$!row-count, :$!col-count);
}

multi method rotate (Z::Cipher:D: CLOCKWISE --> Z::Cipher:D) {
  my @rotated = self.transpose.flip(HORIZONTAL).sym;
	Z::Cipher.new(:sym(@rotated), row-count => $!col-count, col-count => $!row-count);
}

multi method rotate (Z::Cipher:D: ANTICLOCKWISE --> Z::Cipher:D) {
  my @rotated = self.transpose.flip(VERTICAL).sym;
	Z::Cipher.new(:sym(@rotated), row-count => $!col-count, col-count => $!row-count);
}

