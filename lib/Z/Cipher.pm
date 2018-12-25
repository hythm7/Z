use Z::Cipher::File;
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

multi method new (:@sym!) {
  self.bless( :@sym );
}

multi method new (IO::Path :$filename!) {
	my Z::Cipher::File $cipher-file .= new();
  my @sym = $cipher-file.parse(:$filename);
	@sym .= deepmap( -> $label { Z::Cipher::Sym.new_with_label($label) });

  self.bless( :@sym );
}

submethod BUILD (
  :@sym!,
) {


	$!sym-count = [+] @sym; 
	$!row-count = @sym.elems; 
	$!col-count = @sym[0].elems; 
	@!sym = @sym;
}

method gist (Z::Cipher:D:) { 
	put .map(*.label) for @!sym;
}

method sym-count () { $!sym-count }
method row-count () { $!row-count }
method col-count () { $!col-count }

method transpose (Z::Cipher:D: --> Z::Cipher:D) {
  my @transposed;

	for ^$!row-count X ^$!col-count -> ($r, $c) {
    @transposed[$c][$r] = @!sym[$r][$c];
	}
	
	Z::Cipher.new(:sym(@transposed));

}

multi method flip (Z::Cipher:D: HORIZONTAL --> Z::Cipher:D) {
	my @flipped;
  @flipped = @!sym.map( *.reverse );
	Z::Cipher.new(:sym(@flipped));
}

multi method flip (Z::Cipher:D: VERTICAL --> Z::Cipher:D) {
	my @flipped;
  @flipped = @!sym.reverse;
	Z::Cipher.new(:sym(@flipped));
}

multi method rotate (Z::Cipher:D: CLOCKWISE --> Z::Cipher:D) {
  my @rotated = self.transpose.flip(VERTICAL).sym;
	Z::Cipher.new(:sym(@rotated));
}

multi method rotate (Z::Cipher:D: ANTICLOCKWISE --> Z::Cipher:D) {
  my @rotated = self.transpose.flip(HORIZONTAL).sym;
	Z::Cipher.new(:sym(@rotated));
}

