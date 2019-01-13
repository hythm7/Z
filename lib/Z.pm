use GTK::Raw::Types;
use GTK::Compat::Types;
use GTK::Application;
use GTK::CSSProvider;
use GTK::Box;
use GTK::Statusbar;
#use GTK::MenuBar;
#use GTK::MenuItem;
#use GTK::Menu;
use GTK::Grid;
use GTK::Button;
use GTK::FileChooserButton;

#use Z::Util;
use Z::Cipher;
use Z::Cipher::File;


enum WINDOW (
  MAIN   => 0,
  CIPHER => 1,
);

unit class Z;
#  also does Z::Util;
  also is GTK::Application;

submethod BUILD () {


  self.activate.tap({ 
    CATCH { default { .message.say; self.exit } }

    my $box = self.content(MAIN);

    self.window.add($box);  
    self.window.destroy-signal.tap: { self.exit };
    self.show_all();
  });


  self.run;
}

multi method win ( CIPHER, :$filename ) {
	my $grid = Z::Cipher.new(:$filename).grid;
	#my Z::Cipher  $cipher .= new: :$filename;
  my GTK::Window $window      .= new: GTK_WINDOW_TOPLEVEL, :title($filename.basename);
  my $*statusbar = GTK::Statusbar.new;
  my $box =  GTK::Box.new-vbox();
  
  $box.pack_start($grid);
  #$box.pack_start($*statusbar);

  $window.add($box);
  
  $window.show_all();
  self.add_window: $window;
}

multi method content (MAIN) {
  GTK::CSSProvider.new.load-from-path('css/style.css');
  # my GTK::MenuBar  $z-bar          .= new;
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


  my $box = GTK::Box.new-vbox();
  $box.pack_start($chooser);
  $box.pack_start($exit);

  $box;
}

