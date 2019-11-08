use Grid;
use GTK::Raw::Types;
use GTK::Compat::Types;
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

  } );


  $!statusbar = GTK::Statusbar.new;
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

method grams () {

  "U:" ~ +self.gram( UNI   ) ~ " " ~
  "B:" ~ +self.gram( BI    ) ~ " " ~
  "T:" ~ +self.gram( TRI   ) ~ " " ~
  "Q:" ~ +self.gram( QUAD  ) ~ " " ~
  "Q:" ~ +self.gram( QUINT );

}

multi method cmd ( FLIP_HORIZONTAL ) {
  say 'f';
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
multi method cmd ( FLIP_VERTICAL ) {
  say 'F';
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
multi method cmd ( ROTATE_CLOCKWISE ) {
  say 'r';
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

multi method cmd ( ROTATE_ANTICLOCKWISE ) {
  say 'R';
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

multi method cmd ( TRANSPOSE ) {
  say 't';
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

multi method cmd ( MIRROR_HORIZONTAL ) {
  say 'm';
  say $!flowbox.get-selected-children.map(*.get-child.angle += 90);
  $!statusbar.push: $!statusbar.get-context-id( self ), self.grams;
  True;
}

multi method cmd ( MIRROR_VERTICAL ) {
  say 'M';
  say $!flowbox.get-selected-children.map(*.get-child.angle -= 90);
  $!statusbar.push: $!statusbar.get-context-id( self ), self.grams;
  True;
}

multi method cmd ( ANGLE_CLOCKWISE ) {
  say 'a';
  say $!flowbox.get-selected-children.map(*.get-child.angle += 90);
  $!statusbar.push: $!statusbar.get-context-id( self ), self.grams;
  True;
}

multi method cmd ( ANGLE_ANTICLOCKWISE ) {
  say 'A';
  say $!flowbox.get-selected-children.map(*.get-child.angle -= 90);
  $!statusbar.push: $!statusbar.get-context-id( self ), self.grams;
  True;
}

multi method cmd ( COLOR ) {
  say 'c';

  $!colorbox.run;

  my $color = $!colorbox.rgba;
  say $color;

  #my $css = GTK::CSSProvider.new;
  #my $css-s = "#box \{ background-color: { $color.to_string }; \}";

  #$css.load_from_data($css-s);

  #my @child = $!flowbox.get-selected-children;
  #$!statusbar.push: $!statusbar.get-context-id(self), self.grams;
  True;
}

multi method cmd ( SUBSTITUTE, $sym ) {
  say 's';
  $!flowbox.get-selected-children.map({ .get-child.label = $sym });
  $!statusbar.push: $!statusbar.get-context-id(self), self.grams;
  True;
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

  state $change = False;

  given COMMAND( $key ) {

    when $change {
      self.cmd: SUBSTITUTE, $key.chr;
      $change = False;
    }

    when FLIP_HORIZONTAL {
      self.cmd: FLIP_HORIZONTAL;
    }

    when FLIP_VERTICAL {
      self.cmd: FLIP_VERTICAL;
    }

    when ROTATE_CLOCKWISE {
      self.cmd: ROTATE_CLOCKWISE;
    }

    when ROTATE_ANTICLOCKWISE {
      self.cmd: ROTATE_ANTICLOCKWISE;
    }

    when TRANSPOSE {
      self.cmd: TRANSPOSE;
    }

    when MIRROR_VERTICAL {
      self.cmd: MIRROR_VERTICAL;
    }

    when MIRROR_HORIZONTAL {
      self.cmd: MIRROR_HORIZONTAL;
    }

    when ANGLE_CLOCKWISE {
      self.cmd: ANGLE_CLOCKWISE;
    }

    when ANGLE_CLOCKWISE {
      self.cmd: ANGLE_CLOCKWISE;
    }

    when COLOR {
      self.cmd: COLOR;
    }

    when SUBSTITUTE {
      $change = True;
    }

  }
}

