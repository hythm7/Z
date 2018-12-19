use Z::Cipher::File;
use Z::Cipher::Sym;

unit class Z::Cipher;

has Int $!sym-count;
has Int $!row-count;
has Int $!col-count;

has @.sym is required;

multi method new (@sym) {
  self.bless( :@sym );
}

multi method new (IO::Path $filename) {
	my Z::Cipher::File $cipher-file .= new();
  my @sym = $cipher-file.parse(:$filename);

  self.bless( :@sym );
}

submethod BUILD (
  :@sym!,
) {


	$!sym-count = [+] @sym; 
	$!row-count = @sym.elems; 
	$!col-count = @sym[0].elems; 

	@!sym.push: .map( -> $label { Z::Cipher::Sym.new(:$label) }) for @sym;


}

method sym-count () { $!sym-count }
method row-count () { $!row-count }
method col-count () { $!col-count }

method transpose (Z::Cipher:D: --> Z::Cipher:D) {
  my @transposed;

	for ^$!row-count X ^$!col-count -> ($r, $c) {
    @transposed[$c][$r] = @!sym[$r][$c].label;
	}
	
	Z::Cipher.new(@transposed);

}
