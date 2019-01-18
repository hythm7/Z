use GTK::Raw::Types;
use GTK::Compat::Types;
use GTK::Utils::MenuBuilder;
use GTK::FlowBox;
use GTK::FlowBoxChild;
use GTK::Statusbar;
use Z::Cipher::Sym;

enum COMMAND is export (
  VFLIP      => 70,
  HFLIP      => 102,
  AROTATE    => 82,
  CROTATE    => 114,
  TRANSPOSE  => 116,
  VMIRROR    => 77,
  HMIRROR    => 109,
  CANGLE     => 65,
  AANGLE     => 97,
  CHANGE     => 99,
  UNIGRAMS   => 49,
	BIGRAMS    => 50,
	TRIGRAMS   => 51,
	QUADGRAMS  => 52,
	QUINTGRAMS => 53,
);

enum GRAM (
  UNI   => 1,
	BI    => 2,
	TRI   => 3,
	QUAD  => 4,
	QUINT => 5,
);


unit class Z::Cipher;

has Int $!sym-count;
has Int $!row-count;
has Int $!col-count;
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

	my $row-count = $file.lines.elems;
	my $col-count = $file.lines[0].chars;

	my @sym = $file.comb: /\N/;
	self.bless(:@sym, :$row-count, :$col-count);
}

submethod BUILD (
  :@sym!,
  :$row-count!,
  :$col-count!,
) {
	@!sym       = @sym.map( -> $sym { Z::Cipher::Sym.new(sym => $sym, order => $++) });
	$!sym-count = @sym.elems;
	$!row-count = $row-count;
	$!col-count = $col-count;

	@!unigram   = self.gram(UNI);
	@!bigram    = self.gram(BI);
	@!trigram   = self.gram(TRI);
	@!quadgram  = self.gram(QUAD);
	@!quintgram = self.gram(QUINT);

	self.create-menu();
	self.create-flowbox();
  #self.create-statusbar();
	#$*statusbar.push: $*statusbar.get-context-id(self), self.status;
}

method gist (Z::Cipher:D:) {
		put .map(*.sym.label) for @!sym.rotor($!col-count);
}

method sym-count () { $!sym-count }
method row-count () { $!row-count }
method col-count () { $!col-count }
method menu      () { $!menu }
method flowbox   () { $!flowbox }

method transpose () {
  my @transposed;
  my @rotored = @!sym.rotor($!col-count);

	for ^$!row-count X ^$!col-count -> ($r, $c) {
    @transposed[$c][$r] = @rotored[$r][$c];
	}

	@transposed = gather @transposed.deepmap: *.take;

  ($!row-count, $!col-count) .= reverse;
  @!sym = @transposed;
}

multi method hflip () {
	my @flipped = @!sym.rotor($!col-count).map(*.reverse).flat;
  @!sym = @flipped;
	say $!flowbox.get-children;
}

multi method vflip () {
  my @flipped  = @!sym.rotor($!col-count).reverse.flat;
  @!sym = @flipped;
}

multi method crotate () {
  self.transpose();
  self.hflip();
}

multi method arotate () {
  self.transpose();
  self.vflip();
}

multi method gram (Z::Cipher:D: UNI $g) {
	my $b =  0;                 # back step
  my $bag = @!sym>>.sym>>.label.rotor($g => $b).map(*.join).Bag;

	my @gram = gather for $bag.pairs {
		.take;
	}

  @gram;

}

multi method gram (Z::Cipher:D: GRAM $g) {
	my $b = $g - ($g + $g - 1);                 # back step
  my $bag = @!sym>>.sym>>.label.rotor($g => $b).map(*.join).Bag;

	#.say for $bag.pairs;
	my @gram = gather for $bag.pairs {
		.take if .value > 1;
	}

  @gram;

}

my @fbc;
method create-flowbox () {

  $!flowbox = GTK::FlowBox.new;
  $!flowbox.min_children_per_line = $!col-count;
  $!flowbox.max_children_per_line = $!col-count;

  $!flowbox.halign = GTK_ALIGN_START;
  $!flowbox.valign = GTK_ALIGN_START;
  $!flowbox.homogeneous = True;
  
	$!flowbox.set-sort-func(-> $c1, $c2, $ --> gint {
    CATCH { default { .message.say } }
    my gint $r = +$c1.p <=> +$c2.p;
    $r;
  });

  $!flowbox.selection-mode = GTK_SELECTION_MULTIPLE;
  
	#$!flowbox.add: $_ for @!sym;
	for @!sym -> $sym {
		# say $sym.WHAT , " ", $sym.sym, " ", $sym.sym.label;
		$!flowbox.add: $sym;
	}
	#for @!sym -> $sym {
	#	  @fbc.push: (my $child = GTK::FlowBoxChild.new);
	#	$child.add: $sym;
	#	$!flowbox.add: $child;
	#	}
  
  #for ^$!row-count X ^$!col-count -> ($r, $c) {
    #  $!flowbox.attach: @!sym[$++], $c, $r, 1, 1;
    # }

	$!flowbox.add-events: GDK_KEY_PRESS_MASK;
  
  $!flowbox.key-press-event.tap( -> *@a {
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

  });
}

method create-menu () {
  $!menu = GTK::Utils::MenuBuilder.new(:bar, TOP => [
    File => [
      'Open Cipher'   => { 'do' => -> { self.open-cipher-file  } },
      'Save Cipher'   => { 'do' => -> { self.save-cipher-file  } },
      '-'              => False,
      Close            => { 'do' => -> { self.close-file         } },
      Quit             => { 'do' => -> { self.quit               } },
    ],
    View => [
      'Statusbar' => { :check, 'do' => -> { say 'toggled'         } },
    ],
  ]);
}

#method create-statusbar () {
  #  $!statusbar = GTK::Statusbar.new;

  #}



method status () {
  "U:" ~ @!unigram.elems ~ " B:" ~ @!bigram.elems ~ " T:" ~ @!trigram.elems;
}

multi method cmd (HFLIP) {
  say 'f';
  self.hflip;
	$!flowbox.invalidate-sort;
  True;
}
multi method cmd (VFLIP) {
  say 'F';
  self.vflip;
  True;
}
multi method cmd (CROTATE) {
  say 'r';
  self.crotate;
  True;
}

multi method cmd (AROTATE) {
  say 'R';
  self.arotate;
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

multi method cmd (TRANSPOSE) {
  self.transpose();
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
