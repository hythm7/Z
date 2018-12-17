use GTK::Simple::Button;

unit class Z::Cipher::Sym;
  also is GTK::Simple::Button;

has Str $.name;
has Z::Cipher::Sym $.mirror;

