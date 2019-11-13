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

  $!flowbox.column-spacing = 2;
  $!flowbox.row-spacing    = 2;

	$!flowbox.add-events: GDK_KEY_PRESS_MASK;

  $!flowbox.key-press-event.tap( -> *@a {

    my $key = cast(GdkEventKey, @a[1]).keyval;

    @a[*-1].r = self.handle-key: $key;

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

method gram ( Z::Cipher:D: Int:D $gram ) {

	my $back =  1 - $gram;  # back step

  gather for @!sym.map( *.get-child.label ).rotor( $gram => $back ).map(*.join ).Bag.pairs {

		.take if .value > 1;

  }
}

method grams ( :@grams, :$gram = 1 ) {

  my @result = self.gram: $gram;

  return @grams unless @result;

  @grams.push: @result;

  self.grams: :@grams, gram => $gram + 1;

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
  $!statusbar.push: $!statusbar.get-context-id(self), self.grams.map( *.elems );

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
  $!statusbar.push: $!statusbar.get-context-id(self), self.grams.map( *.elems );

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
  $!statusbar.push: $!statusbar.get-context-id(self), self.grams.map( *.elems );

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

  $!statusbar.push: $!statusbar.get-context-id(self), self.grams.map( *.elems );

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


  $!statusbar.push: $!statusbar.get-context-id(self), self.grams.map( *.elems );

}

method mirror-horizontal ( ) {

  $!flowbox.get-selected-children.map(*.get-child.angle += 90);

  $!statusbar.push: $!statusbar.get-context-id(self), self.grams.map( *.elems );

}

method mirror-vertical ( ) {

  $!flowbox.get-selected-children.map(*.get-child.angle -= 90);
  $!statusbar.push: $!statusbar.get-context-id(self), self.grams.map( *.elems );

}

method angle-clockwise ( ) {

  $!statusbar.push: $!statusbar.get-context-id(self), self.grams.map( *.elems );

}

method angle-anticlockwise ( ) {

  $!statusbar.push: $!statusbar.get-context-id(self), self.grams.map( *.elems );

}

method color ( ) {

  $!colorbox.run;

  my $color = $!colorbox.rgba;

  my @child = $!flowbox.get-selected-children;

  @child.map( *.get-child.override-color: GTK_STATE_FLAG_NORMAL, $color );

}

method yank ( ) {

  @*yanked = $!flowbox.get-selected-children.map({ .get-child.label });

}

method paste ( ) {

  my $index = $!flowbox.get-selected-children.first.get-index;

  my @indices = $index X+ ^@*yanked.elems;

  return if @indices.tail > @!sym.end;

  for @indices Z @*yanked -> ( $index, $sym ) {

    $!flowbox.get-child-at-index( $index ).get-child.label = $sym;

  }

  $!statusbar.push: $!statusbar.get-context-id(self), self.grams.map( *.elems );

}


method decipher ( Str:D $sym ) {

  $!flowbox.get-selected-children.map({ .get-child.label = $sym });

  $!statusbar.push: $!statusbar.get-context-id(self), self.grams.map( *.elems );

}

method visual ( $start-x, $start-y, $current-x, $current-y ) {


  $!flowbox.unselect-all;
  for ( $start-x ... $current-x ) X ( $start-y ... $current-y ) -> ( $x, $y ) {

   # WORKAROUND: Convert $x, $y to $index, till p6GtkPlus #43 resolved
   my $index = $x + ( $y * @!sym.columns );

   return unless 0 ≤ $index ≤ @!sym.end;

   my $child =  $!flowbox.get-child-at-index( $index );

   $!flowbox.select-child( $child );

 }

}

submethod handle-key ( Int:D $key ) {

  state $visual   = False;
  state $decipher = False;

  state $start-x;
  state $start-y;
  state $current-x;
  state $current-y;

  state @*yanked;

  given $key {

    when GDK_KEY_Return {

      $visual   = not $visual   if $visual;
      $decipher = not $decipher if $decipher;

      True;
    }

    when GDK_KEY_Escape {

      $visual   = not $visual   if $visual;
      $decipher = not $decipher if $decipher;

      True;
    }

    when $decipher {

      self.decipher: $key.chr;
      
      $decipher = False;

      True;
    }

    when GDK_KEY_v {

      $visual = not $visual;

      return True unless $visual;

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

      True;
    }

    when GDK_KEY_f {

      self.flip-horizontal;

      True;
    }

    when GDK_KEY_F {

      self.flip-vertical;

      True;
    }

    when GDK_KEY_r {

      self.rotate-clockwise;

      True;
    }

    when GDK_KEY_R {

      self.rotate-anticlockwise;

      True;
    }

    when GDK_KEY_t {

      self.transpose;

      True;
    }

    when GDK_KEY_m {

      self.mirror-horizontal;

      True;
    }

    when GDK_KEY_M {

      self.mirror-vertical;

      True;
    }

    when GDK_KEY_a {

      self.angle-clockwise;

      False;
    }

    when GDK_KEY_A {

      self.angle-anticlockwise;

      False;
    }

    when GDK_KEY_c {

      self.color;

      True;
    }

    when GDK_KEY_y {

      self.yank;

      True;
    }

    when GDK_KEY_p {

      self.paste;

      True;
    }

    when GDK_KEY_d {

      $decipher = True;

    }

    when GDK_KEY_k {

      if $visual {
        $current-y -= 1 if $current-y > 0;
        self.visual: $start-x, $start-y, $current-x, $current-y;
      }

      True;
    }

    when GDK_KEY_j {

      if $visual {
        $current-y += 1 if $current-y < @!sym.rows - 1;
        self.visual: $start-x, $start-y, $current-x, $current-y;
      }

      True;
    }

    when GDK_KEY_h {

      if $visual {
        $current-x -= 1 if $current-x > 0;
        self.visual: $start-x, $start-y, $current-x, $current-y;
      }

      True;
    }

    when GDK_KEY_l {

      if $visual {
        $current-x += 1 if $current-x < @!sym.columns - 1;
        self.visual: $start-x, $start-y, $current-x, $current-y;
      }

      True;
    }

    default {
      False;
    }


  }
}

