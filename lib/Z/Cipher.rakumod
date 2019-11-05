use Grid;
use GTK::Raw::Types;
use GTK::Compat::Types;
use GTK::Utils::MenuBuilder;
use GTK::FlowBox;
use GTK::FlowBoxChild;
use GTK::Statusbar;
use Z::Cipher::Util;
use Z::Cipher::Sym;


# hack till .flwoboxchild.deref works
my @fbc;
my %order;

unit class Z::Cipher;

has Int $!sym-count;
has Int $!rows;
has Int $!columns;
has     @!unigram;
has     @!bigram;
has     @!trigram;
has     @!quadgram;
has     @!quintgram;

has @!sym;

has GTK::FlowBox   $!flowbox;
has GTK::Statusbar $!statusbar;


method new (IO::Path :$filename!) {
	my $file = slurp $filename;
	return Nil unless [==] (.chars for $file.lines);

	my $rows = $file.lines.elems;
	my $columns = $file.lines[0].chars;

	my @sym = $file.comb: /\N/;
	self.bless(:@sym, :$rows, :$columns);
}

submethod BUILD (
  :@sym!,
  :$rows!,
  :$columns!,
) {

	@!sym       = @sym.map( -> $label { Z::Cipher::Sym.new($label) });
	$!sym-count = @sym.elems;
	$!rows      = $rows;
	$!columns   = $columns;

	@!unigram   = self.gram(UNI);
	@!bigram    = self.gram(BI);
	@!trigram   = self.gram(TRI);
	@!quadgram  = self.gram(QUAD);
	@!quintgram = self.gram(QUINT);

	self!create-flowbox();

  $*statusbar.push: $*statusbar.get-context-id(self), self.status;

}

method gist (Z::Cipher:D:) {
  put .map(*.label) for @!sym.rotor($!columns);
}

method sym-count () { $!sym-count }
method rows      () { $!rows      }
method columns   () { $!columns   }
method flowbox   () { $!flowbox   }

method gram (Z::Cipher:D: GRAM $g ) {
	my $b =  1 - $g;  # back step
  my $bag = @!sym.map(*.label).rotor($g => $b).map(*.join).Bag;

	#.say for $bag.pairs;
	my @gram = gather for $bag.pairs {
		.take if .value > 1;
	}

  say @gram;
  @gram;
}

method status () {
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
    @fbc := @fbc.flip: :@horizontal;
  }
  else {
    @fbc := @fbc.flip: :horizontal;
  }

	%order{ +.FlowBoxChild.p } = $++ for @fbc;
	$!flowbox.invalidate-sort;
  $*statusbar.push: $*statusbar.get-context-id(self), self.status;
	True;
}
multi method cmd ( FLIP_VERTICAL ) {
  say 'F';
  my @vertical = $!flowbox.get-selected-children.map(*.get-index);

  if @vertical {
    @fbc := @fbc.flip: :@vertical;
  }
  else {
    @fbc := @fbc.flip: :vertical;
  }


  %order{ +.FlowBoxChild.p } = $++ for @fbc;
	$!flowbox.invalidate-sort;
  $*statusbar.push: $*statusbar.get-context-id(self), self.status;
  True;
}
multi method cmd ( ROTATE_CLOCKWISE ) {
  say 'r';
  my @clockwise = $!flowbox.get-selected-children.map(*.get-index);

  if @clockwise {
    @fbc := @fbc.rotate: :@clockwise;
  }
  else {
    @fbc := @fbc.rotate: :clockwise;
  }


  $!flowbox.min_children_per_line = @fbc.columns;
  $!flowbox.max_children_per_line = @fbc.columns;

  %order{ +.FlowBoxChild.p } = $++ for @fbc;
	$!flowbox.invalidate-sort;
  $*statusbar.push: $*statusbar.get-context-id(self), self.status;
  True;
}

multi method cmd ( ROTATE_ANTICLOCKWISE ) {
  say 'R';
  my @anticlockwise = $!flowbox.get-selected-children.map(*.get-index);

  if @anticlockwise {
    @fbc := @fbc.rotate: :@anticlockwise;
  }
  else {
    @fbc := @fbc.rotate: :anticlockwise;
  }


  $!flowbox.min_children_per_line = @fbc.columns;
  $!flowbox.max_children_per_line = @fbc.columns;

  %order{ +.FlowBoxChild.p } = $++ for @fbc;
	$!flowbox.invalidate-sort;
  $*statusbar.push: $*statusbar.get-context-id(self), self.status;
  True;
}

multi method cmd ( TRANSPOSE ) {
  say 't';
  my @indices = $!flowbox.get-selected-children.map(*.get-index);

  if @indices {
    @fbc := @fbc.transpose: :@indices;
  }
  else {
    @fbc := @fbc.transpose;
  }

  $!flowbox.min_children_per_line = @fbc.columns;
  $!flowbox.max_children_per_line = @fbc.columns;

  %order{ +.FlowBoxChild.p } = $++ for @fbc;
	$!flowbox.invalidate-sort;
  $*statusbar.push: $*statusbar.get-context-id(self), self.status;
  True;
}

multi method cmd ( MIRROR_HORIZONTAL ) {
  say 'm';
  say $!flowbox.get-selected-children.map(*.get-child.angle += 90);
  $*statusbar.push: $*statusbar.get-context-id(self), self.status;
  True;
}

multi method cmd ( MIRROR_VERTICAL ) {
  say 'M';
  say $!flowbox.get-selected-children.map(*.get-child.angle -= 90);
  $*statusbar.push: $*statusbar.get-context-id(self), self.status;
  True;
}

multi method cmd ( ANGLE_CLOCKWISE ) {
  say 'a';
  say $!flowbox.get-selected-children.map(*.get-child.angle += 90);
  $*statusbar.push: $*statusbar.get-context-id(self), self.status;
  True;
}

multi method cmd ( ANGLE_ANTICLOCKWISE ) {
  say 'A';
  say $!flowbox.get-selected-children.map(*.get-child.angle -= 90);
  $*statusbar.push: $*statusbar.get-context-id(self), self.status;
  True;
}

multi method cmd ( CHANGE, $sym ) {
  say 'c';
  $!flowbox.get-selected-children.map({ .get-child.label = $sym });
  $*statusbar.push: $*statusbar.get-context-id(self), self.status;
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


method !create-flowbox () {

  $!flowbox                          = GTK::FlowBox.new;
  $!flowbox.halign                   = GTK_ALIGN_START;
  $!flowbox.valign                   = GTK_ALIGN_START;
  $!flowbox.selection-mode           = GTK_SELECTION_MULTIPLE;
  $!flowbox.activate-on-single-click = False;
  $!flowbox.homogeneous              = True;

	$!flowbox.set-sort-func(-> $c1, $c2, $ --> gint {
    CATCH { default { .message.say } }
    my gint $r = %order{ +$c1.p } <=> %order{ +$c2.p };
    $r;
  });


  for @!sym -> $sym {
    my $child = GTK::FlowBoxChild.new;
    $child.add: $sym;
    %order{ +$child.FlowBoxChild.p } = $++;
    $!flowbox.add: $child;
  }


  @fbc = $!flowbox.get-children;

	@fbc does Grid[:$!columns];

  $!flowbox.min_children_per_line = @fbc.columns;
  $!flowbox.max_children_per_line = @fbc.columns;


	$!flowbox.add-events: GDK_KEY_PRESS_MASK;


  $!flowbox.key-press-event.tap( -> *@a {

    my $key = cast(GdkEventKey, @a[1]).keyval;

    self.handle-key: $key;

    @a[*-1].r = 0;

  });

}

submethod handle-key ( Int:D $key ) {

  state $change = False;

  given COMMAND( $key ) {

    when $change {
      self.cmd: CHANGE, $key.chr;
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

    when CHANGE {
      $change = True;
    }
  }
}

#method create-statusbar () {
#  $!statusbar = GTK::Statusbar.new;

#}



