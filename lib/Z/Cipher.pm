use GTK::Simple::Button;
use Z::Cipher::File;

unit class Z::Cipher;

has Int $!sym-count;
has Int $!row-count;
has Int $!col-count;

has @.sym is required;

multi method new (IO::Path :$filename) {
	my Z::Cipher::File $cipher-file .= new();
  my @sym = $cipher-file.parse(:$filename);

  self.bless( :@sym );
}

multi method new (:@sym) {
  self.bless( :@sym );
}

submethod BUILD (
  :@sym!,
) {


	$!sym-count = [+] @sym; 
	$!row-count = @sym.elems; 
	$!col-count = @sym[0].elems; 

  @!sym.push: .map( -> $label { GTK::Simple::Button.new(:$label) }) for @sym;


}

method sym-count () { $!sym-count }
method row-count () { $!row-count }
method col-count () { $!col-count }


