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
use GTK::FileChooserButton; # convert to dialog, "o" to open
use GTK::Dialog::ColorChooser;

use Z::Cipher;

enum WINDOW (
  MAIN   => 0,
  CIPHER => 1,
);

unit class Z;
  also is GTK::Application;

submethod BUILD () {


  self.activate.tap({

    CATCH { default { .message.say; self.exit } }

    GTK::CSSProvider.new.load-from-path(%?RESOURCES<z.css>);

    # my GTK::MenuBar   $z-bar          .= new;
    # my GTK::MenuItem  $z-menu-item    .= new: :label<Z>;
    # my GTK::MenuItem  $quit-menu-item .= new: :label<Goodbye!>;
    # my GTK::Menu      $z-menu         .= new;
    #
    # # $z-menu-item.set-sub-menu($z-menu);
    # $z-menu.append($quit-menu-item);
    # $z-bar.append($z-menu-item);
    # $quit-menu-item.activate.tap: { self.exit }

    my GTK::FileChooserButton $chooser .= new('Pick a cipher', GTK_FILE_CHOOSER_ACTION_OPEN);
    my GTK::Button $exit .= new_with_label: <Goodbye!>;


    $chooser.selection-changed.tap: {
      self.add-window: Z::Cipher.new( filename => $chooser.filename.IO).window;
    };

    $exit.clicked.tap:     { self.exit };


    my $box = GTK::Box.new-vbox();

    $box.pack_start($chooser);
    $box.pack_start($exit);

    self.window.add($box);
    self.window.destroy-signal.tap: { self.exit };
    self.show_all();

  });

  self.run;
}
