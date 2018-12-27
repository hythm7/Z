use GTK::Raw::Types;
use GTK::Box;
#use GTK::MenuBar;
#use GTK::MenuItem;
#use GTK::Menu;
use GTK::Grid;
use GTK::Button;
use GTK::FileChooserButton;
use Z::Cipher;
use Z::Cipher::File;

enum WINDOW (
  MAIN   => 0,
  CIPHER => 1,
);

unit role Z::Util;

multi method content (MAIN) {
	#	my GTK::MenuBar  $z-bar          .= new;
	#my GTK::MenuItem $z-menu-item    .= new: :label<Z>;
	#my GTK::MenuItem $quit-menu-item .= new: :label<Goodbye!>;
	#my GTK::Menu     $z-menu         .= new;

	#$z-menu-item.set-sub-menu($z-menu);
	#$z-menu.append($quit-menu-item);
	#$z-bar.append($z-menu-item);
	#$quit-menu-item.activate.tap: { self.exit }

	my GTK::FileChooserButton $chooser .= new('Pick a cipher', GTK_FILE_CHOOSER_ACTION_OPEN);
	my GTK::Button $exit .= new_with_label: <Goodbye!>;


	$chooser.selection-changed.tap: { self.win(CIPHER, :filename($chooser.filename.IO)) };
	$exit.clicked.tap:     { self.exit };


  my $box =  GTK::Box.new-vbox();
	$box.pack_start($chooser);
 	$box.pack_start($exit);

  $box;
}


multi method content (CIPHER, :$filename) {
	my Z::Cipher  $cipher .= new: :$filename;
	#$cipher .= flip(VERTICAL);
	#$cipher .= flip(HORIZONTAL);
	$cipher .= rotate(ANTICLOCKWISE);
	my GTK::Grid   $cipher-grid .= new;
	my @sym = gen-grid :$cipher;
	$cipher-grid.attach: |$_ for @sym;

	$cipher-grid;

}

multi gen-grid (Z::Cipher :$cipher) {
	my $i = 0;
  my @sym;
  
	for ^$cipher.row-count X ^$cipher.col-count -> ($r, $c) {
		my $sym = $cipher.sym[$i++];
    my $item =  [$sym, $c, $r, $sym.w, $sym.h];
		push @sym, $item;
    
	}
	return @sym;
}

