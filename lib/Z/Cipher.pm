use GTK::Simple::Button;

unit class Z::Cipher;

has IO::Path $!file;
has Int $.no-of-sym;
has Int $.no-of-row;
has Int $.no-of-col;

has @.sym[Str];

method BUILD (
  IO::Path :$filename,
) {
  my $file = slurp $filename;
  return Nil unless [==] (.chars for $file.lines);
	$!no-of-sym = $file.comb(/\N/).elems; 
	$!no-of-row = $file.lines.elems; 
	$!no-of-col = Int($!no-of-sym / $!no-of-row); 

  my $line-number = 0;
  for $file.lines -> $line {
    @!sym[$line-number] = $line.comb.map( -> $sym {GTK::Simple::Button.new(:label($sym)) } );
		$line-number++;
	}
}

