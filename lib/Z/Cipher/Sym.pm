use GTK::Raw::Types;
use GTK::FlowBoxChild;
use GTK::Label;

unit class Z::Cipher::Sym;
  also is GTK::FlowBoxChild;

	#has GTK::Label $.sym;
	has $.sym;
	has $.order;

	#method new (Str :$sym, Int :$order) {
		#	  self.bless(:$sym, :$order);
		#}
  
  submethod BUILD (:$sym, :$order) {
		say $sym;
		$!sym = GTK::Label.new($sym);
		say $!sym;
		#$!sym = GTK::Label.new('h');
    $!sym.max-width-chars = 1;
		$!order = $order;
		self.add($!sym);
  }

	#method sym { $!sym };

