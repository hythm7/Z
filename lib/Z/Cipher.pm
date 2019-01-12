use GTK::Raw::Types;
use GTK::Grid;
use Z::Cipher::Sym;

unit class Z::Cipher;
  also is GTK::Grid;

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
	my $o = nextwith;

	#my $file = slurp $filename;
	#return Nil unless [==] (.chars for $file.lines);

	#my $row-count = $file.lines.elems;
	#my $col-count = $file.lines[0].chars;

	#my @sym = $file.comb: /\N/;
	#$o.bless(:@sym, :$row-count, :$col-count);
	$o;
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
  
  #self.halign = GTK_ALIGN_START;
  #self.valign = GTK_ALIGN_START;
  #self.row-homogeneous = True;
  #self.column-homogeneous = True;

  #for ^$!row-count X ^$!col-count -> ($r, $c) {
    #  self.attach: @!sym[$++], $c, $r, 1, 1;
    #}

	#$*statusbar.push: $*statusbar.get-context-id(self), self.status;
}

method gist (Z::Cipher:D:) { 
		put .map(*.label) for @!sym.rotor($!col-count);
}

method sym-count () { $!sym-count }
method row-count () { $!row-count }
method col-count () { $!col-count }

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
  @!sym .= rotor($!col-count).map(*.reverse).flat;
}

multi method flip (VERTICAL) {
  @!sym .= rotor($!col-count).reverse.flat;
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
    self.child-set-int(@!sym[$++], 'top_attach',  $r);
    self.child-set-int(@!sym[$++], 'left_attach', $c);
  }
}

method status () {
  "U:" ~ @!unigram.elems ~ " B:" ~ @!bigram.elems ~ " T:" ~ @!trigram.elems;
}

method cmd (COMMAND :$cmd) {
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
      self.cipher.rotate(CLOCKWISE);
      self.update-grid;
      True;
    }

    when AROTATE {
      self.cipher.rotate(ANTICLOCKWISE);
      self.update-grid;
      True;
    }

    when TRANSPOSE {
      self.cipher.transpose;
      self.update-grid;
      True;
    }
  }
}
