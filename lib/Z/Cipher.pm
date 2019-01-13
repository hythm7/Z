use GTK::Raw::Types;
use GTK::Compat::Types;
use GTK::Grid;
use Z::Cipher::Sym;

unit class Z::Cipher;

  has GTK::Grid $!grid;

enum COMMAND is export (
  VFLIP => 70,
  HFLIP => 102,

  AROTATE => 82,
  CROTATE => 114,

  TRANSPOSE => 116,
);

enum DIRECTION is export (
  HORIZONTAL    => 'h',
  VERTICAL      => 'v',
  CLOCKWISE     => 'c',
  ANTICLOCKWISE => 'a',
);

enum GRAM (
  UNI   => 1,
	BI    => 2,
	TRI   => 3,
	QUAD  => 4,
	QUINT => 5,
);


has Int $!sym-count;
has Int $!row-count;
has Int $!col-count;
has     @!unigram;
has     @!bigram;
has     @!trigram;
has     @!quadgram;
has     @!quintgram;

has @!sym;

#multi method new (:@sym!, :$row-count!, :$col-count!) {
#  self.bless( :@sym, :$row-count, :$col-count );
#}

#hack untill GTK Inheritance fixed;
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
    @a[*-1].r = self.cmd(:$cmd);
  });


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

multi method flip (HORIZONTAL) {
	my @flipped = @!sym.rotor($!col-count).map(*.reverse).flat;
  @!sym = @flipped;
}

multi method flip (VERTICAL) {
  my @flipped  = @!sym.rotor($!col-count).reverse.flat;
  @!sym = @flipped;
}

multi method rotate (CLOCKWISE) {
  self.transpose;
  self.flip(HORIZONTAL);
}

multi method rotate (ANTICLOCKWISE) {
  self.transpose;
  self.flip(VERTICAL);
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

method update-grid () {
  for ^$!row-count X ^$!col-count -> ($r, $c) {
    $!grid.child-set-int(@!sym[$++], 'top_attach',  $r);
    $!grid.child-set-int(@!sym[$++], 'left_attach', $c);
  }
}

method status () {
  "U:" ~ @!unigram.elems ~ " B:" ~ @!bigram.elems ~ " T:" ~ @!trigram.elems;
}

method cmd (:$cmd) {
  given $cmd {
    when HFLIP {
      self.flip(HORIZONTAL);
      self.update-grid;
      True;
    }
    when VFLIP {
      self.flip(VERTICAL);
      self.update-grid;
      True;
    }

    when CROTATE {
      self.rotate(CLOCKWISE);
      self.update-grid;
      True;
    }

    when AROTATE {
      self.rotate(ANTICLOCKWISE);
      self.update-grid;
      True;
    }

    when TRANSPOSE {
      self.transpose;
      self.update-grid;
      True;
    }
  }
}
