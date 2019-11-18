use Grid;
use GTK::Raw::Types;
use GTK::Compat::Types;
use GTK::Compat::KeySyms;
use GTK::Window;
use GTK::FlowBox;
use GTK::FlowBoxChild;
use GTK::Statusbar;
use GTK::Menu;
use GTK::MenuItem;
use GTK::Dialog::ColorChooser;
use GTK::Dialog::FileChooser;
use GTK::CSSProvider;;
use Z::Cipher::Sym;
use Z::Cipher::Utils;


unit class Z::Cipher;

has @!sym;
has %!order;

has GTK::Window               $!window;
has GTK::FlowBox              $!flowbox;
has GTK::Statusbar            $!statusbar;
has GTK::Dialog::ColorChooser $!colorbox;
has GTK::Menu                 $!menu;


method grams ( Bool:D :$selection = False ) {

  my @sym = $selection
    ?? @!sym[ $!flowbox.get-selected-children.map( *.get-index ).sort ]
    !! @!sym;

  grams :@sym;

}

method grams-count ( Bool:D :$selection = False ) {

  $!statusbar.push: $!statusbar.get-context-id( self ), self.grams( :$selection ).map( +* );

}

method gram ( Int:D $gram ) {

  $!flowbox.unselect-all;

  my @gram = gram :@!sym :$gram;

  my $back = 1 - $gram;

  @!sym.rotor( $gram => $back )
    ==> grep({ .map( *.get-child.label ).join ~~ any @gram } )
    ==> flat( )
    ==> map( -> $child { $!flowbox.select-child: $child } );

}

method flip-horizontal ( ) {

  my @horizontal = $!flowbox.get-selected-children.map( *.get-index );

  if @horizontal {

    @!sym := @!sym.flip: :@horizontal;

  }

  else {

    @!sym := @!sym.flip: :horizontal;

  }

	%!order{ .get-child.name } = $++ for @!sym;
	$!flowbox.invalidate-sort;

  self.grams-count;

}

method flip-vertical ( ) {

  my @vertical = $!flowbox.get-selected-children.map( *.get-index );

  if @vertical {

    @!sym := @!sym.flip: :@vertical;

  }

  else {

    @!sym := @!sym.flip: :vertical;

  }

  %!order{ .get-child.name } = $++ for @!sym;
	$!flowbox.invalidate-sort;

  self.grams-count;

}

method rotate-clockwise ( ) {

  my @clockwise = $!flowbox.get-selected-children.map( *.get-index );

  if @clockwise {

    @!sym := @!sym.rotate: :@clockwise;

  }

  else {

    @!sym := @!sym.rotate: :clockwise;

  }

  $!flowbox.min_children_per_line = @!sym.columns;
  $!flowbox.max_children_per_line = @!sym.columns;

  %!order{ .get-child.name } = $++ for @!sym;
	$!flowbox.invalidate-sort;

  self.grams-count;

}

method rotate-anticlockwise ( ) {

  my @anticlockwise = $!flowbox.get-selected-children.map( *.get-index );

  if @anticlockwise {

    @!sym := @!sym.rotate: :@anticlockwise;

  }

  else {

    @!sym := @!sym.rotate: :anticlockwise;

  }

  $!flowbox.min_children_per_line = @!sym.columns;
  $!flowbox.max_children_per_line = @!sym.columns;

  %!order{ .get-child.name } = $++ for @!sym;
	$!flowbox.invalidate-sort;

  self.grams-count;

}

method transpose ( ) {

  my @index = $!flowbox.get-selected-children.map(*.get-index);

  if @index {

    @!sym := @!sym.transpose: :@index;

  }

  else {

    @!sym := @!sym.transpose;

  }

  $!flowbox.min_children_per_line = @!sym.columns;
  $!flowbox.max_children_per_line = @!sym.columns;

  %!order{ .get-child.name } = $++ for @!sym;
	$!flowbox.invalidate-sort;

  self.grams-count;

}

method mirror-horizontal ( ) {

  $!flowbox.get-selected-children.map(*.get-child.angle += 90);

  self.grams-count;

}

method mirror-vertical ( ) {

  $!flowbox.get-selected-children.map(*.get-child.angle -= 90);

  self.grams-count;

}

method angle-clockwise ( ) {

  self.grams-count;

}

method angle-anticlockwise ( ) {

  self.grams-count;

}

method color ( ) {

  $!colorbox.run;

  my $color = $!colorbox.rgba;

  my $css = GTK::CSSProvider.new;

  my @child = $!flowbox.get-selected-children;

  my $style = qq:to/END/;

    {
      @child.map( -> $child {

        "#{ $child.get-child.name } \{ color: { $color.to_string }; \}";

      } );
    }
    END

  $css.load-from-data: $style;
}

method yank ( ) {

  @*yanked = $!flowbox.get-selected-children.map({ .get-child.label });

}

method paste ( ) {

  my $index = $!flowbox.get-selected-children.first.get-index;

  my @index = $index X+ ^@*yanked.elems;

  return if @index.tail > @!sym.end;

  for @index Z @*yanked -> ( $index, $sym ) {

    @!sym[ $index ].get-child.label = $sym;

  }

  self.grams-count;

}


method decipher ( Str:D $sym ) {

  $!flowbox.get-selected-children.map({ .get-child.label = $sym });

  self.grams-count;

}

method visual ( $start-x, $start-y, $current-x, $current-y ) {

  $!flowbox.unselect-all;

  for ( $start-x ... $current-x ) X ( $start-y ... $current-y ) -> ( $x, $y ) {

   my $index = $x + ( $y * @!sym.columns );

   return unless 0 ≤ $index ≤ @!sym.end;

   my $child =  @!sym[ $index ];

   $!flowbox.select-child( $child );

 }

}

method new-cipher ( Bool:D :$selection = False ) {

  my @index = $selection
    ?? $!flowbox.get-selected-children.map( *.get-index ).sort
    !! @!sym.keys;

  my $columns = @!sym.has-subgrid: :@index;

  return unless $columns;

  my $rows = @index.elems div $columns;

  my Z::Cipher::Sym @sym = @!sym[ @index ].map( *.get-child );

  self.new: :@sym, :$rows, :$columns;

}

submethod handle-key ( GdkEventAny:D $event ) {

  my $key = cast( GdkEventKey, $event );

  state $visual   = False;
  state $decipher = False;

  state $start-x;
  state $start-y;
  state $current-x;
  state $current-y;

  state @*yanked;

  given $key.keyval {

    when GDK_KEY_Return {

      $visual   = not $visual   if $visual;
      $decipher = not $decipher if $decipher;

      True;
    }

    when GDK_KEY_Escape {

      $visual   = not $visual   if $visual;
      $decipher = not $decipher if $decipher;

      $!flowbox.unselect-all;

      True;
    }

    when $decipher { self.decipher: .chr; $decipher = False; True; }

    when GDK_KEY_v {

      $visual = not $visual;

      return True unless $visual;

      # TODO: Start at child under cursor

      my $index   = $!flowbox.get-selected-children.head.get-index // 0;

      if $index ~~ 0 {

        $start-x = 0;
        $start-y = 0;

      }

      else {

        $start-x = $index mod @!sym.columns;
        $start-y = $index div @!sym.columns;

      }

      $current-x = $start-x;
      $current-y = $start-y;

      False;
    }

    when GDK_KEY_f { self.flip-horizontal;         False; }
    when GDK_KEY_F { self.flip-vertical;           False; }
    when GDK_KEY_r { self.rotate-clockwise;        False; }
    when GDK_KEY_R { self.rotate-anticlockwise;    False; }
    when GDK_KEY_t { self.transpose;               False; }
    when GDK_KEY_m { self.mirror-horizontal;       False; }
    when GDK_KEY_M { self.mirror-vertical;         False; }
    when GDK_KEY_a { self.angle-clockwise;         False; }
    when GDK_KEY_A { self.angle-anticlockwise;     False; }
    when GDK_KEY_g { self.grams-count;             False; }
    when GDK_KEY_G { self.grams-count: :selection; False; }
    when GDK_KEY_n { self.new-cipher;              False; }
    when GDK_KEY_N { self.new-cipher:  :selection; False; }
    when GDK_KEY_1 { self.gram: 1;                 False; }
    when GDK_KEY_2 { self.gram: 2;                 False; }
    when GDK_KEY_3 { self.gram: 3;                 False; }
    when GDK_KEY_4 { self.gram: 4;                 False; }
    when GDK_KEY_5 { self.gram: 5;                 False; }
    when GDK_KEY_6 { self.gram: 6;                 False; }
    when GDK_KEY_7 { self.gram: 7;                 False; }
    when GDK_KEY_8 { self.gram: 8;                 False; }
    when GDK_KEY_9 { self.gram: 9;                 False; }
    when GDK_KEY_c { self.color;                   False; }
    when GDK_KEY_y { self.yank;                    False; }
    when GDK_KEY_p { self.paste;                   False; }
    when GDK_KEY_Q { self.quit;                    False; }

    when GDK_KEY_d {

       $decipher = True;

       False;

    }

    when GDK_KEY_k {

      if $visual {

        $current-y -= 1 if $current-y > 0;

        self.visual: $start-x, $start-y, $current-x, $current-y;

      }

      False;
    }

    when GDK_KEY_j {

      if $visual {

        $current-y += 1 if $current-y < @!sym.rows - 1;

        self.visual: $start-x, $start-y, $current-x, $current-y;

      }

      False;
    }

    when GDK_KEY_h {

      if $visual {

        $current-x -= 1 if $current-x > 0;

        self.visual: $start-x, $start-y, $current-x, $current-y;

      }

      False;
    }

    when GDK_KEY_l {

      if $visual {

        $current-x += 1 if $current-x < @!sym.columns - 1;

        self.visual: $start-x, $start-y, $current-x, $current-y;

      }

      False;
    }

    default {

      False;

    }

  }
}

submethod handle-button ( GdkEventAny:D $event ) {

  my $button = cast( GdkEventButton, $event );

  given $button.button {

    when GDK_BUTTON_SECONDARY {

      $!menu.popup-at-pointer: $event;

      True;
    }

    default {

      False;

    }

  }

}

method window ( ) { $!window }

method quit ( ) { $!window.close }

submethod TWEAK ( ) {

  $!window = GTK::Window.new: GTK_WINDOW_TOPLEVEL, :title<Cipher>;

  $!flowbox = GTK::FlowBox.new;
 
  $!flowbox.halign = GTK_ALIGN_START;
  $!flowbox.valign = GTK_ALIGN_START;

  $!flowbox.selection-mode = GTK_SELECTION_MULTIPLE;

  $!flowbox.homogeneous              = True;
  $!flowbox.activate-on-single-click = False;

  $!flowbox.name = 'cipher';

  @!sym.map( -> $sym {  $!flowbox.add: $sym } );

	$!flowbox.set-sort-func(-> $c1, $c2, $ --> gint {

    CATCH { default { .message.say } }

    %!order{ +$c1.p } <=> %!order{ +$c2.p };

  });


  @!sym = $!flowbox.get-children;


  $!flowbox.min_children_per_line = @!sym.columns;
  $!flowbox.max_children_per_line = @!sym.columns;

  $!flowbox.column-spacing = 2;
  $!flowbox.row-spacing    = 2;

  $!flowbox.key-press-event.tap( -> *@a {

    @a[*-1].r = self.handle-key: @a[1];

  });

  $!flowbox.button-press-event.tap( -> *@a {

    @a[*-1].r = self.handle-button: @a[1];

  });


  $!flowbox.child-activated.tap( -> @ {

    my $sym   = $!flowbox.get-selected-children.head.get-child.label;
    my @child = $!flowbox.get-children.grep({ .get-child.label ~~ $sym });

    @child.map( -> $child { $!flowbox.select-child: $child } );

    $!statusbar.push: $!statusbar.get-context-id(self), "$sym { +@child}";

  } );


  $!statusbar = GTK::Statusbar.new;
  $!statusbar.margin = 0;

  $!colorbox  = GTK::Dialog::ColorChooser.new: 'Choose color', $!window;

  $!menu = GTK::Menu.new;

  my $save  = GTK::MenuItem.new-with-mnemonic: '_save';
  my $quit = GTK::MenuItem.new-with-mnemonic: '_quit';

  $save.activate.tap( -> *@ {

    my $chooser = GTK::Dialog::FileChooser.new: 'Save', $!window, GTK_FILE_CHOOSER_ACTION_SAVE;

    if $chooser.run ~~  GTK_RESPONSE_OK {

      my $filename = $chooser.filename.IO;

      $filename.spurt: @!sym.map( *.get-child.label ).rotor( @!sym.columns ).map( *.join ).join( "\n" ) with $filename;
    }

  } );

  $quit.activate.tap( -> *@ { self.quit } );

  $!menu.append: $save;
  $!menu.append: $quit;

  $!menu.show-all;

  my $box = GTK::Box.new-vbox( );

  # WORKAROUND: shrink window
  $box.size-allocate.tap( -> *@a {
  
    my $size =  $box.get-preferred-size.head;
  
    $!window.resize( 1, 1 );
  
  } );

  $box.pack_start( $!flowbox );
  $box.pack_end( $!statusbar );

  $!window.add( $box );


  $!window.show_all( );

  $!flowbox.unselect-all;

  $!statusbar.push: $!statusbar.get-context-id( self ), self.grams.map( *.elems );

}

multi submethod BUILD ( Z::Cipher::Sym:D :@sym, :$rows!, :$columns! ) {

  my $css = GTK::CSSProvider.new;

  for @sym {

    my $child = GTK::FlowBoxChild.new;

    my $label = .label;

    # my $color = .get-style-context.get-color;

    my $sym = Z::Cipher::Sym.new: $label;

    $child.add: $sym;

    $sym.name = $child.FlowBoxChild.p.Int;

    @!sym.push: $child;

  }

  @!sym.map( { %!order{ .get-child.name } = $++ } );

	@!sym does Grid[ :$columns ];
}

multi submethod BUILD ( Str:D :@sym!, :$rows!, :$columns! ) {

  for @sym -> $label {

    my $child = GTK::FlowBoxChild.new;

    my $sym = Z::Cipher::Sym.new: $label;

    $child.add: $sym;

    $sym.name = $child.FlowBoxChild.p.Int;

    @!sym.push: $child;

  }

  @!sym.map( { %!order{ .get-child.name } = $++ } );

	@!sym does Grid[ :$columns ];
 
}

multi method new ( :@sym!, :$rows!, :$columns! ) {

	self.bless: :@sym :$rows :$columns;

}

multi method new ( IO::Path :$filename! ) {

	return Nil unless [==] (.chars for $filename.lines);

	my $rows    = $filename.lines.elems;
	my $columns = $filename.lines[0].chars;

	my Str @sym = $filename.comb( /\N/ );

	nextwith :@sym :$rows :$columns;

}

