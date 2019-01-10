use GTK::Raw::Types;
use GTK::Button;

unit class Z::Cipher::Sym;
  also is GTK::Button;

submethod BUILD () {
  self.relief = GTK_RELIEF_NONE;
  
  #self.hexpand = True;
  #self.vexpand = True;
  
  #self.halign = GTK_ALIGN_CENTER;
  #self.valign = GTK_ALIGN_CENTER;
}
