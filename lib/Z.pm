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
  my Z::Cipher  $cipher .= new: :$filename;
  my GTK::Window $window      .= new: GTK_WINDOW_TOPLEVEL, :title($filename.basename);
  my $*statusbar = GTK::Statusbar.new;
  my $box =  GTK::Box.new-vbox();
  #$cipher .= flip(VERTICAL);
  #$cipher .= flip(HORIZONTAL);
  #$cipher .= rotate(ANTICLOCKWISE);
  my GTK::Grid   $grid .= new;
  $grid.halign = GTK_ALIGN_START;
  $grid.valign = GTK_ALIGN_START;
  $grid.row-homogeneous = True;
  $grid.column-homogeneous = True;
  #$grid.row-spacing = 7;
  #$grid.column-spacing = 7;
  my @sym = gen-grid-childs :$cipher;
  $grid.attach: |$_ for @sym;


  $box.pack_start($grid);
  $box.pack_start($*statusbar);



  $window.add($box);
  $window.add-events: GDK_KEY_PRESS_MASK;
  $window.key-press-event.tap( -> ($win, $event, $data, $value) {
    my $key = cast(GdkEventKey, $event);
    given $key.keyval {
        when HFLIP {
          $cipher .= flip(HORIZONTAL);
          arrange-grid-childs :$grid, :$cipher;
          say 1;
        }
        when VFLIP {
          $cipher .= flip(VERTICAL);
          arrange-grid-childs :$grid, :$cipher;
        }

        when CROTATE {
          $cipher .= rotate(CLOCKWISE);
          arrange-grid-childs :$grid, :$cipher;
        }

        when AROTATE {
          $cipher .= rotate(ANTICLOCKWISE);
          arrange-grid-childs :$grid, :$cipher;
        }

        when TRANSPOSE {
          $cipher .= transpose;
          arrange-grid-childs :$grid, :$cipher;
        }

      }
      
    $value.r = 0;
  });
  
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




sub gen-grid-childs (Z::Cipher :$cipher) {
  my @sym;

  for ^$cipher.row-count X ^$cipher.col-count -> ($r, $c) {
    my $sym = $cipher.sym[$++];
    my $item =  ($sym, $c, $r, 1, 1);
    push @sym, $item;

  }
  return @sym;
}

sub arrange-grid-childs (:$grid, Z::Cipher :$cipher) {
  for ^$cipher.row-count X ^$cipher.col-count -> ($r, $c) {
    $grid.child-set-int($cipher.sym[$++], 'top_attach',  $r);
    $grid.child-set-int($cipher.sym[$++], 'left_attach', $c);
  }
}

