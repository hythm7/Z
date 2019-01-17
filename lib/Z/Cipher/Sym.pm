use GTK::Raw::Types;
use GTK::Label;

unit class Z::Cipher::Sym;
  also is GTK::Label;
  
  submethod BUILD () {
    self.max-width-chars = 1;
  }

