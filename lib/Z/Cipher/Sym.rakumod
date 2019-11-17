use GTK::Label;

unit class Z::Cipher::Sym;
  also is GTK::Label;

method TWEAK () {

  #self.name = 'sym';

  self.width-chars = 1;

  #  self.size-allocate.tap( -> *@a {
  #
  #    self.set-size-request: @a[1].height, @a[1].height;
  #
  #  } );

}
