use GTK::Button;

unit class Z::Cipher::Sym;
  also is GTK::Button;

has Int $.w = 1;
has Int $.h = 1;

method gist () {
  self.label;
}
