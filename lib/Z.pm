use GTK::Raw::Types;
use GTK::Application;
use GTK::CSSProvider;

use Z::Util;
use Z::Cipher;
use Z::Cipher::File;

unit class Z;
  also does Z::Util;
  also is GTK::Application;

submethod BUILD () {
	GTK::CSSProvider.new.load-from-path('css/style.css');

	self.activate.tap({ 
		CATCH { default { .message.say; self.exit } }
    self.window.add(self.content(MAIN));  
    self.window.destroy-signal.tap: { self.exit };
	  self.show_all();
  });


	self.run;
}

multi method win ( CIPHER, :$filename ) {
	my GTK::Window $window      .= new: GTK_WINDOW_TOPLEVEL, :title($filename.basename);
	$window.add(self.content(CIPHER, :$filename));
	$window.show_all();
	self.add_window: $window;
}
