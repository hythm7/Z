use GTK::Simple;
use GTK::Simple::App;

unit class Z;
  also is GTK::Simple::App;

my @sym = <a b c d e f g h i j k m n o p q r s t u v w x y z>;

submethod BUILD () {

	my \a = GTK::Simple::Button.new(:label<a>);
	my \b = GTK::Simple::Button.new(:label<b>);
	my \c = GTK::Simple::Button.new(:label<c>);
	my \d = GTK::Simple::Button.new(:label<d>);
	my \e = GTK::Simple::Button.new(:label<e>);
	my \f = GTK::Simple::Button.new(:label<f>);
	my \g = GTK::Simple::Button.new(:label<g>);
	my \h = GTK::Simple::Button.new(:label<h>);
	my \i = GTK::Simple::Button.new(:label<i>);
	my \j = GTK::Simple::Button.new(:label<j>);
	my \k = GTK::Simple::Button.new(:label<k>);
	my \l = GTK::Simple::Button.new(:label<l>);
#	my \m = GTK::Simple::Button.new(:label<m>);
	my \n = GTK::Simple::Button.new(:label<n>);
	my \o = GTK::Simple::Button.new(:label<o>);
	my \p = GTK::Simple::Button.new(:label<p>);
#	my \q = GTK::Simple::Button.new(:label<q>);
	my \r = GTK::Simple::Button.new(:label<r>);
#	my \s = GTK::Simple::Button.new(:label<s>);
	my \t = GTK::Simple::Button.new(:label<t>);
	my \u = GTK::Simple::Button.new(:label<u>);
	my \v = GTK::Simple::Button.new(:label<v>);
	my \w = GTK::Simple::Button.new(:label<w>);
	my \x = GTK::Simple::Button.new(:label<x>);
#	my \y = GTK::Simple::Button.new(:label<y>);
	my \z = GTK::Simple::Button.new(:label<z>);


	my @pairs = self.gen-grid-pairs(:x(17), :y(20));

  my $grid = GTK::Simple::Grid.new(@pairs);

  self.set-content($grid);
}

method gen-grid-pairs (:$x!, :$y!) {
  my @pairs;
	my $s = 0;
  my @cipher = 0 .. 339;
  
	loop (my $i = 1; $i <= $y; $i++) {
	  loop (my $j = 1; $j <= $x; $j++) {
        my $pair =  [$i, $j, 1, 1] => GTK::Simple::Button.new(:label(@cipher[$s++].Str));
				push @pairs, $pair;
		}
	}
	return @pairs;
}

method gen-cipher-from-sym (:$x!, :$y!, :@sym) {
  my @cipher;
	loop (my $i = 1; $i <= $y; $i++) {
	  loop (my $j = 1; $j <= $x; $j++) {
				push @cipher[$i; $j], @sym.pick;
		}
	}
	return  @cipher;
}
