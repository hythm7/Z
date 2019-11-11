use Grid;
use GTK::Raw::Types;
use GTK::Compat::Types;
use GTK::Compat::KeySyms;
use GTK::Utils::MenuBuilder;
use GTK::Window;
use GTK::FlowBox;
use GTK::FlowBoxChild;
use GTK::Statusbar;
use GTK::Dialog::ColorChooser;
use Z::Cipher::Util;
use Z::Cipher::Sym;


unit class Z::Cipher;

has @!sym;
has %!order;
has $!grams;

has GTK::Window               $!window;
has GTK::FlowBox              $!flowbox;
has GTK::Statusbar            $!statusbar;
has GTK::Dialog::ColorChooser $!colorbox;

method new (IO::Path :$filename!) {

	my $file = slurp $filename;

	return Nil unless [==] (.chars for $file.lines);

	my $rows    = $file.lines.elems;
	my $columns = $file.lines[0].chars;

	my @sym = $file.comb: /\N/;

	self.bless(:@sym, :$rows, :$columns);

}


submethod BUILD (

  :@sym!,
  :$rows!,
  :$columns!,

) {

  $!window = GTK::Window.new: GTK_WINDOW_TOPLEVEL, :title<Cipher>;

  $!flowbox                          = GTK::FlowBox.new;
  $!flowbox.halign                   = GTK_ALIGN_START;
  $!flowbox.valign                   = GTK_ALIGN_START;
  $!flowbox.selection-mode           = GTK_SELECTION_MULTIPLE;
  $!flowbox.activate-on-single-click = False;
  $!flowbox.homogeneous              = True;
  $!flowbox.name = 'cipher';

  for @sym -> $sym {
    my $child = GTK::FlowBoxChild.new;
    $child.add: Z::Cipher::Sym.new: $sym;
    %!order{ +$child.FlowBoxChild.p } = $++;
    $!flowbox.add: $child;
  }

	$!flowbox.set-sort-func(-> $c1, $c2, $ --> gint {
    CATCH { default { .message.say } }
    %!order{ +$c1.p } <=> %!order{ +$c2.p };
  });


  @!sym = $!flowbox.get-children;

	@!sym does Grid[:$columns];

  $!flowbox.min_children_per_line = @!sym.columns;
  $!flowbox.max_children_per_line = @!sym.columns;


	$!flowbox.add-events: GDK_KEY_PRESS_MASK;

  $!flowbox.key-press-event.tap( -> *@a {

    my $key = cast(GdkEventKey, @a[1]).keyval;

    self.handle-key: $key;

    @a[*-1].r = 0;

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

  my $box = GTK::Box.new-vbox( );

  $box.pack_start( $!flowbox );
  $box.pack_end( $!statusbar );

  $!window.add( $box );

  $!window.show_all( );

  #$!statusbar.push: $!statusbar.get-context-id(self), self.grams;

}

method window ( ) { $!window   }

method gram (Z::Cipher:D: GRAM $g ) {

	my $b =  1 - $g;  # back step

  gather for @!sym.map( *.get-child.label ).rotor($g => $b).map(*.join).Bag.pairs {

		.take if .value > 1;

  }
}

method grams ( ) {

  "U:" ~ +self.gram( UNI   ) ~ " " ~
  "B:" ~ +self.gram( BI    ) ~ " " ~
  "T:" ~ +self.gram( TRI   ) ~ " " ~
  "Q:" ~ +self.gram( QUAD  ) ~ " " ~
  "Q:" ~ +self.gram( QUINT );

}

method flip-horizontal ( ) {

  my @horizontal = $!flowbox.get-selected-children.map(*.get-index);

  if @horizontal {
    @!sym := @!sym.flip: :@horizontal;
  }
  else {
    @!sym := @!sym.flip: :horizontal;
  }

	%!order{ +.FlowBoxChild.p } = $++ for @!sym;
	$!flowbox.invalidate-sort;
  #$!statusbar.push: $!statusbar.get-context-id(self), self.grams;
	True;
}

method flip-vertical ( ) {

  my @vertical = $!flowbox.get-selected-children.map(*.get-index);

  if @vertical {
    @!sym := @!sym.flip: :@vertical;
  }
  else {
    @!sym := @!sym.flip: :vertical;
  }


  %!order{ +.FlowBoxChild.p } = $++ for @!sym;
	$!flowbox.invalidate-sort;
  $!statusbar.push: $!statusbar.get-context-id(self), self.grams;
  True;
}

method rotate-clockwise ( ) {

  my @clockwise = $!flowbox.get-selected-children.map(*.get-index);

  if @clockwise {
    @!sym := @!sym.rotate: :@clockwise;
  }
  else {
    @!sym := @!sym.rotate: :clockwise;
  }


  $!flowbox.min_children_per_line = @!sym.columns;
  $!flowbox.max_children_per_line = @!sym.columns;

  %!order{ +.FlowBoxChild.p } = $++ for @!sym;
	$!flowbox.invalidate-sort;
  $!statusbar.push: $!statusbar.get-context-id(self), self.grams;
  True;
}

method rotate-anticlockwise ( ) {

  my @anticlockwise = $!flowbox.get-selected-children.map(*.get-index);

  if @anticlockwise {
    @!sym := @!sym.rotate: :@anticlockwise;
  }
  else {
    @!sym := @!sym.rotate: :anticlockwise;
  }


  $!flowbox.min_children_per_line = @!sym.columns;
  $!flowbox.max_children_per_line = @!sym.columns;

  %!order{ +.FlowBoxChild.p } = $++ for @!sym;
	$!flowbox.invalidate-sort;
  $!statusbar.push: $!statusbar.get-context-id(self), self.grams;

  True;
}

method transpose ( ) {

  my @indices = $!flowbox.get-selected-children.map(*.get-index);

  if @indices {
    @!sym := @!sym.transpose: :@indices;
  }
  else {
    @!sym := @!sym.transpose;
  }

  $!flowbox.min_children_per_line = @!sym.columns;
  $!flowbox.max_children_per_line = @!sym.columns;

  %!order{ +.FlowBoxChild.p } = $++ for @!sym;
	$!flowbox.invalidate-sort;
  $!statusbar.push: $!statusbar.get-context-id( self ), self.grams;
  True;
}

method mirror-horizontal ( ) {

  $!flowbox.get-selected-children.map(*.get-child.angle += 90);
  $!statusbar.push: $!statusbar.get-context-id( self ), self.grams;
  True;
}

method mirror-vertical ( ) {

  $!flowbox.get-selected-children.map(*.get-child.angle -= 90);
  $!statusbar.push: $!statusbar.get-context-id( self ), self.grams;
  True;
}

method angle-clockwise ( ) {

  say $!flowbox.get-selected-children.map(*.get-child.angle += 90);
  $!statusbar.push: $!statusbar.get-context-id( self ), self.grams;
  True;
}

method angle-anticlockwise ( ) {

  say $!flowbox.get-selected-children.map(*.get-child.angle -= 90);
  $!statusbar.push: $!statusbar.get-context-id( self ), self.grams;
  True;
}

method color ( ) {

  $!colorbox.run;

  my $color = $!colorbox.rgba;

  my @child = $!flowbox.get-selected-children;

  @child.map( *.get-child.override-color: GTK_STATE_FLAG_NORMAL, $color );

  

  #my $css = GTK::CSSProvider.new;
  #my $css-s = "#box \{ background-color: { $color.to_string }; \}";

  #$css.load_from_data($css-s);

  $!statusbar.push: $!statusbar.get-context-id(self), self.grams;
  True;
}

method yank ( ) {

  @*yanked = $!flowbox.get-selected-children.map({ .get-child.label });
  True;
}

method paste ( ) {

  my $index = $!flowbox.get-selected-children.first.get-index;

  my @indices = $index X+ ^@*yanked.elems;

  return if @indices.tail > @!sym.end;

  for @indices Z @*yanked -> ( $index, $sym ) {

    $!flowbox.get-child-at-index( $index ).get-child.label = $sym;

  }

  True;
}


method visual ( $start-x, $start-y, $current-x, $current-y ) {

  #say $!flowbox.get-child-at-pos( 0, 0 ).get-child.WHAT;

  $!flowbox.unselect-all;
  for ( $start-x ... $current-x ) X ( $start-y ... $current-y ) -> ( $x, $y ) {

   # WORKAROUND: Convert $x, $y to $index, till p6GtkPlus #43 resolved
   my $index = $x + ( $y * @!sym.columns );
 
   return unless 0 ≤ $index ≤ @!sym.end;

   my $child =  $!flowbox.get-child-at-index( $index );

   $!flowbox.select-child( $child );

 }

}

multi method cmd ( UNIGRAMS ) {
  #say self.gram(UNI).elems;
  say $!flowbox.get-children();
  True;
}

multi method cmd ( BIGRAMS ) {
  say self.gram(BI).elems;
  True;
}

multi method cmd ( TRIGRAMS ) {
  say self.gram(TRI).elems;
  True;
}

multi method cmd ( QUADGRAMS ) {
  say self.gram(QUAD).elems;
  True;
}

multi method cmd ( QUINTGRAMS ) {
  say self.gram(QUINT).elems;
  True;
}


submethod handle-key ( Int:D $key ) {

  state $visual = False;
  state $start-x;
  state $start-y;
  state $current-x;
  state $current-y;

  state @*yanked;

  given $key {


    when GDK_KEY_v {

      $visual = not $visual;

      return unless $visual;

      my $index   = $!flowbox.get-selected-children.first.get-index;

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

    }

    when GDK_KEY_f {
      self.flip-horizontal;
    }

    when GDK_KEY_F {
      self.flip-vertical;
    }

    when GDK_KEY_r {
      self.rotate-clockwise;
    }

    when GDK_KEY_R {
      self.rotate-anticlockwise;
    }

    when GDK_KEY_t {
      self.transpose;
    }

    when GDK_KEY_m {
      self.mirror-horizontal;
    }

    when GDK_KEY_M {
      self.mirror-vertical;
    }

    when GDK_KEY_a {
      self.angle-clockwise;
    }

    when GDK_KEY_A {
      self.angle-anticlockwise;
    }

    when GDK_KEY_c {
      self.color;
    }

    when GDK_KEY_y {
      self.yank;
    }

    when GDK_KEY_p {
      self.paste;
    }

    when GDK_KEY_k {
      if $visual {
        $current-y -= 1 if $current-y > 0;
        self.visual: $start-x, $start-y, $current-x, $current-y;
      }
    }

    when GDK_KEY_j {
      if $visual {
        $current-y += 1 if $current-y < @!sym.rows - 1;
        self.visual: $start-x, $start-y, $current-x, $current-y;
      }
    }

    when GDK_KEY_h {
      if $visual {
        $current-x -= 1 if $current-x > 0;
        self.visual: $start-x, $start-y, $current-x, $current-y;
      }
    }

    when GDK_KEY_l {
      if $visual {
        $current-x += 1 if $current-x < @!sym.columns - 1;
        self.visual: $start-x, $start-y, $current-x, $current-y;
      }
    }

  }
}

