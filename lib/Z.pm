use GTK::Simple;
use GTK::Simple::Raw;
use GTK::Simple::App;

use Z::Util;
use Z::Cipher;
use Z::Cipher::File;

unit class Z;
  also does Z::Util;
  also is GTK::Simple::App;

submethod BUILD () {

  self.set-content(self.window(MAIN));  
	self.show-all();
	self.run;
}

multi method window ( MAIN ) {
  self.content(MAIN);
}

multi method window ( CIPHER, :$filename ) {
	my GTK::Simple::Window $window      .= new: :title($filename.basename);
  $window.set-content(self.content(CIPHER, :$filename));
	$window.show();
}
