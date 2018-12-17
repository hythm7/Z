use GTK::Simple;
use GTK::Simple::App;

use Z::Cipher;

unit class Z;
  also is GTK::Simple::App;

method gen-grid (:$filename) {
  my @pairs;
  my $cipher = Z::Cipher.new: :$filename;
  
	loop (my $j = 0; $j < $cipher.no-of-col; $j++) {
	  loop (my $i = 0; $i < $cipher.no-of-row; $i++) {
        my $pair =  [$j, $i, 1, 1] => $cipher.sym[$i][$j];
				push @pairs, $pair;
		}
	}
	say $cipher.sym[0][7].^methods;;
	return GTK::Simple::Grid.new(@pairs);
}

