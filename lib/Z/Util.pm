use GTK::Simple;
use GTK::Simple::Raw;
use Z::Cipher;
use Z::Cipher::File;

enum WINDOW (
  MAIN   => 0,
  CIPHER => 1,
);

unit role Z::Util;

multi method content (MAIN) {

	my GTK::Simple::MenuBar  $z-bar          .= new;
	my GTK::Simple::MenuItem $z-menu-item    .= new: :label<Z>;
	my GTK::Simple::MenuItem $quit-menu-item .= new: :label<Goodbye!>;
	my GTK::Simple::Menu     $z-menu         .= new;

	$z-menu-item.set-sub-menu($z-menu);
	$z-menu.append($quit-menu-item);
	$z-bar.append($z-menu-item);
	$quit-menu-item.activate.tap: { self.exit }

	my GTK::Simple::FileChooserButton $chooser .= new;
	my GTK::Simple::Button            $exit    .= new: :label<Goodbye!>;

	$chooser.file-set.tap: { self.window(CIPHER, :filename($chooser.file-name.IO)) };
	$exit.clicked.tap:     { self.exit };


  my $content =  GTK::Simple::VBox.new([
	  { :widget($z-bar), :expand(False) },
	  { :widget($chooser), :expand(False) },
	  { :widget($exit), :expand(False) },
	]);

  $content;
}


multi method content (CIPHER, :$filename) {
	my Z::Cipher  $cipher .= new: :$filename;
	$cipher .= flip(VERTICAL);
	my GTK::Simple::Grid   $cipher-grid .= new: grid-pairs :$cipher;

	$cipher-grid;

}

multi grid-pairs (Z::Cipher :$cipher) {
  my @pairs;
  
	for ^$cipher.row-count X ^$cipher.col-count -> ($r, $c) {
		my $sym = $cipher.sym[$r][$c];
    my $pair =  [$c, $r, $sym.w, $sym.h] => $sym;

		push @pairs, $pair;
    
	}
	return @pairs;
}

