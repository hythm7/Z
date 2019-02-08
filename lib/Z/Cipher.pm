use Array::Grid;
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

has                $!menu;

has GTK::FlowBox   $!flowbox;
#has GTK::Statusbar $!statusbar;


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
	$!rows = $rows;
	$!columns = $columns;

	@!unigram   = self.gram(UNI);
	@!bigram    = self.gram(BI);
	@!trigram   = self.gram(TRI);
	@!quadgram  = self.gram(QUAD);
	@!quintgram = self.gram(QUINT);

  #se.create-menu();
	self!create-flowbox();
  #self.create-statusbar();
	#$*statusbar.push: $*statusbar.get-context-id(self), self.status;
}

method gist (Z::Cipher:D:) {
  put .map(*.label) for @!sym.rotor($!columns);
}

method sym-count () { $!sym-count }
method rows () { $!rows }
method columns () { $!columns }
method menu      () { $!menu }
method flowbox   () { $!flowbox }



multi method gram (Z::Cipher:D: UNI $g) {
	my $b =  0;                 # back step
  my $bag = @!sym.map(*.label).rotor($g => $b).map(*.join).Bag;

	my @gram = gather for $bag.pairs {
		.take;
	}

  @gram;
:w

}

multi method gram (Z::Cipher:D: GRAM $g) {
	my $b = $g - ($g + $g - 1);                 # back step
  my $bag = @!sym.map(*.label).rotor($g => $b).map(*.join).Bag;

	#.say for $bag.pairs;
	my @gram = gather for $bag.pairs {
		.take if .value > 1;
	}

  @gram;

}

method status () {
  "U:" ~ @!unigram.elems ~ " B:" ~ @!bigram.elems ~ " T:" ~ @!trigram.elems;
}

multi method cmd (HFLIP) {
  say 'f';
  my @subgrid = $!flowbox.get-selected-children.map(*.get-index);

  if @subgrid {
    @fbc := @fbc.hflip: :@subgrid;
  }
  else {
    @fbc := @fbc.hflip;
  }

	%order{ +.flowboxchild.p } = $++ for @fbc;
	$!flowbox.invalidate-sort;
	True;
}
multi method cmd (VFLIP) {
  say 'F';
  my @subgrid = $!flowbox.get-selected-children.map(*.get-index);

  if @subgrid {
    @fbc := @fbc.vflip: :@subgrid;
  }
  else {
    @fbc := @fbc.vflip;
  }


  %order{ +.flowboxchild.p } = $++ for @fbc;
	$!flowbox.invalidate-sort;
  True;
}
multi method cmd (CROTATE) {
  say 'r';
  my @subgrid = $!flowbox.get-selected-children.map(*.get-index);

  if @subgrid {
    @fbc := @fbc.crotate: :@subgrid;
  }
  else {
    @fbc := @fbc.crotate;
  }

  
  $!flowbox.min_children_per_line = @fbc.columns;
  $!flowbox.max_children_per_line = @fbc.columns;

  %order{ +.flowboxchild.p } = $++ for @fbc;
	$!flowbox.invalidate-sort;
  True;
}

multi method cmd (AROTATE) {
  say 'R';
  my @subgrid = $!flowbox.get-selected-children.map(*.get-index);

  if @subgrid {
    @fbc := @fbc.arotate: :@subgrid;
  }
  else {
    @fbc := @fbc.arotate;
  }


  $!flowbox.min_children_per_line = @fbc.columns;
  $!flowbox.max_children_per_line = @fbc.columns;

  %order{ +.flowboxchild.p } = $++ for @fbc;
	$!flowbox.invalidate-sort;
  True;
}

multi method cmd (TRANSPOSE) {
  say 'R';
  my @subgrid = $!flowbox.get-selected-children.map(*.get-index);

  if @subgrid {
    @fbc := @fbc.transpose: :@subgrid;
  }
  else {
    @fbc := @fbc.transpose;
  }


	say '------';

  $!flowbox.min_children_per_line = @fbc.columns;
  $!flowbox.max_children_per_line = @fbc.columns;


  %order{ +.flowboxchild.p } = $++ for @fbc;
	$!flowbox.invalidate-sort;
  True;
}

multi method cmd (HMIRROR) {
  say 'm';
  say 'HFLIP';
  say $!flowbox.get-selected-children.map(*.get-child.angle += 90);
  True;
}

multi method cmd (VMIRROR) {
  say 'M';
  say $!flowbox.get-selected-children.map(*.get-child.angle -= 90);
  True;
}

multi method cmd (CANGLE) {
  say 'a';
  say $!flowbox.get-selected-children.map(*.get-child.angle += 90);
  True;
}

multi method cmd (AANGLE) {
  say 'A';
  say $!flowbox.get-selected-children.map(*.get-child.angle -= 90);
  True;
}

multi method cmd (CHANGE) {
  say 'c';
  $!flowbox.get-selected-children.map({ .get-child.sym.label = 'z' });
  True;
}


multi method cmd (UNIGRAMS) {
  #say self.gram(UNI).elems;
  say $!flowbox.get-children();
  True;
}
multi method cmd (BIGRAMS) {
  say self.gram(BI).elems;
  True;
}
multi method cmd (TRIGRAMS) {
  say self.gram(TRI).elems;
  True;
}
multi method cmd (QUADGRAMS) {
  say self.gram(QUAD).elems;
  True;
}
multi method cmd (QUINTGRAMS) {
  say self.gram(QUINT).elems;
  True;
}

method !fb-key-press-event (@a) {
  my $cmd = cast(GdkEventKey, @a[1]).keyval;

    given $cmd {
      @a[*-1].r = self.cmd(HFLIP)      when HFLIP;
      @a[*-1].r = self.cmd(VFLIP)      when VFLIP;
      @a[*-1].r = self.cmd(CROTATE)    when CROTATE;
      @a[*-1].r = self.cmd(AROTATE)    when AROTATE;
      @a[*-1].r = self.cmd(TRANSPOSE)  when TRANSPOSE;
      @a[*-1].r = self.cmd(HMIRROR)    when HMIRROR;
      @a[*-1].r = self.cmd(VMIRROR)    when VMIRROR;
      @a[*-1].r = self.cmd(CANGLE)     when CANGLE;
      @a[*-1].r = self.cmd(AANGLE)     when AANGLE;
      @a[*-1].r = self.cmd(CHANGE)     when CHANGE;
      @a[*-1].r = self.cmd(UNIGRAMS)   when UNIGRAMS;
      @a[*-1].r = self.cmd(BIGRAMS)    when BIGRAMS;
      @a[*-1].r = self.cmd(TRIGRAMS)   when TRIGRAMS;
      @a[*-1].r = self.cmd(QUADGRAMS)  when QUADGRAMS;
      @a[*-1].r = self.cmd(QUINTGRAMS) when QUINTGRAMS;

      default { @a[*-1].r = 0 };
    }
}

method !create-flowbox () {

  $!flowbox = GTK::FlowBox.new;
  $!flowbox.halign = GTK_ALIGN_START;
  $!flowbox.valign = GTK_ALIGN_START;
  $!flowbox.homogeneous = True;
  
	$!flowbox.set-sort-func(-> $c1, $c2, $ --> gint {
    CATCH { default { .message.say } }
    %order{ +$c1.p } <=> %order{ +$c2.p };
  });

  $!flowbox.selection-mode = GTK_SELECTION_MULTIPLE;
  
  for @!sym -> $sym {
    my $child = GTK::FlowBoxChild.new;
    $child.add: $sym;
    %order{ +$child.flowboxchild.p } = $++;
    $!flowbox.add: $child;
  }
  
  @fbc = $!flowbox.get-children;

	@fbc does Array::Grid[:$!columns];
  
  $!flowbox.min_children_per_line = @fbc.columns;
  $!flowbox.max_children_per_line = @fbc.columns;

  
	$!flowbox.add-events: GDK_KEY_PRESS_MASK;
  
  $!flowbox.key-press-event.tap( -> *@a { self!fb-key-press-event(@a) });
}

#method create-statusbar () {
  #  $!statusbar = GTK::Statusbar.new;

  #}



