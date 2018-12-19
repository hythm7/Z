use GTK::Simple;
use GTK::Simple::App;

use Z::Enum;
use Z::Cipher;
use Z::Cipher::File;

unit class Z;
  also is GTK::Simple::App;

method load-cipher (:$filename) {
	my Z::Cipher $cipher .= new(:$filename);

	#$cipher .= transpose;
	#$cipher .= flip(LEFT);
	#$cipher .= rotate(RIGHT);
	$cipher .= rotate(LEFT);

$cipher.gist;
	#my $grid = self.gen-grid(:$cipher);
	#self.set-content($grid);
}

method gen-grid (Z::Cipher :$cipher) {
  my @pairs;
	#$cipher.transpose;
  
	for ^$cipher.row-count X ^$cipher.col-count -> ($r, $c) {
		#my $pair =  [$c, $r, 1, 1] => GTK::Simple::Button.new(:label($cipher.sym[$r][$c]));
    my $pair =  [$c, $r, 1, 1] => $cipher.sym[$r][$c];
		push @pairs, $pair;
    
	}
	#say @pairs[0].value.label;
	#say @pairs[1].value.label;
	return GTK::Simple::Grid.new(@pairs);

}


