use Z::Enum;
use Z::Cipher::File;
use Z::Cipher::Sym;

unit class Z::Cipher;

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
	@sym .= deepmap( -> $label { Z::Cipher::Sym.new(:$label) });

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

multi method flip (Z::Cipher:D: LEFT --> Z::Cipher:D) {
	my @flipped;
  @flipped = @!sym.map( *.reverse );
	Z::Cipher.new(:sym(@flipped));
}

multi method flip (Z::Cipher:D: RIGHT --> Z::Cipher:D) {
	my @flipped;
  @flipped = @!sym.map( *.reverse );
	Z::Cipher.new(:sym(@flipped));
}

multi method flip (Z::Cipher:D: UP --> Z::Cipher:D) {
	my @flipped;
  @flipped = @!sym.reverse;
	Z::Cipher.new(:sym(@flipped));
}

multi method flip (Z::Cipher:D: DOWN --> Z::Cipher:D) {
	my @flipped;
  @flipped = @!sym.reverse;
	Z::Cipher.new(:sym(@flipped));
}

multi method rotate (Z::Cipher:D: LEFT --> Z::Cipher:D) {
  my @rotated = self.transpose.flip(UP).sym;
	Z::Cipher.new(:sym(@rotated));
}

multi method rotate (Z::Cipher:D: RIGHT --> Z::Cipher:D) {
  my @rotated = self.transpose.flip(RIGHT).sym;
	Z::Cipher.new(:sym(@rotated));
}

