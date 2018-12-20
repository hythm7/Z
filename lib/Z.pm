use GTK::Simple;
use GTK::Simple::Raw;
use GTK::Simple::App;

use Z::Util;
use Z::Cipher;
use Z::Cipher::File;

unit class Z;
  also is GTK::Simple::App;

submethod BUILD () {
  my $chooser;

  $chooser = GTK::Simple::FileChooserButton.new();
	$chooser.file-set.tap: { self.open-cipher(:filename($chooser.file-name.IO)) };

  my $exit;
	
	$exit = GTK::Simple::Button.new(label => "Goodbye!");
	$exit.clicked.tap: { self.exit; };


  my $main-window =  GTK::Simple::VBox.new([
	  { :widget($chooser), :expand(False) },
	  { :widget($exit), :expand(False) },
	]);

  self.set-content($main-window);  
	self.run;
}


method open-cipher (:$filename! ) {
	my GTK::Simple::Window $window      .= new: :title($filename.basename);
	my Z::Cipher           $cipher      .= new: :$filename;
	my GTK::Simple::Grid   $cipher-grid .= new: grid-pairs :$cipher;

	$window.set-content($cipher-grid);
	$window.show();
	#$cipher .= transpose;
	#$cipher .= flip(LEFT);
	#$cipher .= rotate(RIGHT);
	#$cipher .= rotate(RIGHT);
}
