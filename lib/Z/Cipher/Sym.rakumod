use GTK::Label;

unit class Z::Cipher::Sym;
  also is GTK::Label;

method TWEAK () {

  self.name = 'sym';

  self.width-chars = 1;

}
