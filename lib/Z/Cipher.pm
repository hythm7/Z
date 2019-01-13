use GTK::Raw::Types;
use GTK::Compat::Types;
use GTK::Grid;
use Z::Cipher::Sym;

enum COMMAND is export (
  VFLIP      => 70,
  HFLIP      => 102,

  AROTATE    => 82,
  CROTATE    => 114,

  TRANSPOSE  => 116,

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

has GTK::Grid $!grid;


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
	@!sym       = @sym.map( -> $label { Z::Cipher::Sym.new_with_label($label) });
	$!sym-count = @sym.elems;
	$!row-count = $row-count;
	$!col-count = $col-count;

	@!unigram   = self.gram(UNI);
	@!bigram    = self.gram(BI);
	@!trigram   = self.gram(TRI);
	@!quadgram  = self.gram(QUAD);
	@!quintgram = self.gram(QUINT);

	self.create-grid();
	#$*statusbar.push: $*statusbar.get-context-id(self), self.status;
}

method gist (Z::Cipher:D:) {
		put .map(*.label) for @!sym.rotor($!col-count);
}

method sym-count () { $!sym-count }
method row-count () { $!row-count }
method col-count () { $!col-count }
method grid      () { $!grid }

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
  my $bag = @!sym>>.label.rotor($g => $b).map(*.join).Bag;

	my @gram = gather for $bag.pairs {
		.take;
	}

  @gram;

}

multi method gram (Z::Cipher:D: GRAM $g) {
	my $b = $g - ($g + $g - 1);                 # back step
  my $bag = @!sym>>.label.rotor($g => $b).map(*.join).Bag;

	#.say for $bag.pairs;
	my @gram = gather for $bag.pairs {
		.take if .value > 1;
	}

  @gram;

}

method create-grid () {

  $!grid = GTK::Grid.new;
  $!grid.halign = GTK_ALIGN_START;
  $!grid.valign = GTK_ALIGN_START;
  $!grid.row-homogeneous = True;
  $!grid.column-homogeneous = True;

  for ^$!row-count X ^$!col-count -> ($r, $c) {
    $!grid.attach: @!sym[$++], $c, $r, 1, 1;
  }

	$!grid.add-events: GDK_KEY_PRESS_MASK;
  
  $!grid.key-press-event.tap( -> *@a {
    my $cmd = cast(GdkEventKey, @a[1]).keyval;

		given $cmd {
      @a[*-1].r = self.cmd(HFLIP)      when HFLIP;
      @a[*-1].r = self.cmd(VFLIP)      when VFLIP;
      @a[*-1].r = self.cmd(CROTATE)    when CROTATE;
      @a[*-1].r = self.cmd(AROTATE)    when AROTATE;
      @a[*-1].r = self.cmd(TRANSPOSE)  when TRANSPOSE;

      @a[*-1].r = self.cmd(UNIGRAMS)   when UNIGRAMS;
      @a[*-1].r = self.cmd(BIGRAMS)    when BIGRAMS;
      @a[*-1].r = self.cmd(TRIGRAMS)   when TRIGRAMS;
      @a[*-1].r = self.cmd(QUADGRAMS)  when QUADGRAMS;
      @a[*-1].r = self.cmd(QUINTGRAMS) when QUINTGRAMS;

			default { @a[*-1].r = 0 };
		}

  });
}

method update-grid () {
  for ^$!row-count X ^$!col-count -> ($r, $c) {
    $!grid.child-set-int(@!sym[$++], 'top_attach',  $r);
    $!grid.child-set-int(@!sym[$++], 'left_attach', $c);
  }
}

method status () {
  "U:" ~ @!unigram.elems ~ " B:" ~ @!bigram.elems ~ " T:" ~ @!trigram.elems;
}

multi method cmd (HFLIP) {
  self.hflip();
  self.update-grid;
  True;
}
multi method cmd (VFLIP) {
  self.vflip();
  self.update-grid;
  True;
}
multi method cmd (CROTATE) {
  self.crotate();
  self.update-grid;
  True;
}

multi method cmd (AROTATE) {
  self.arotate();
  self.update-grid;
  True;
}

multi method cmd (TRANSPOSE) {
  self.transpose();
  self.update-grid;
  True;
}
multi method cmd (UNIGRAMS) {
  say self.gram(UNI).elems;
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
