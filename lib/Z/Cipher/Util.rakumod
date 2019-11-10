unit module Z::Cipher::Util;

enum COMMAND is export (
  FLIP_VERTICAL        => 70,
  FLIP_HORIZONTAL      => 102,
  ROTATE_ANTICLOCKWISE => 82,
  ROTATE_CLOCKWISE     => 114,
  TRANSPOSE            => 116,
  MIRROR_VERTICAL      => 77,
  MIRROR_HORIZONTAL    => 109,
  ANGLE_CLOCKWISE      => 65,
  ANGLE_ANTICLOCKWISE  => 97,
  SUBSTITUTE           => 115,
  COLOR                => 99,
  VISUAL               => 118,
  YANK                 => 121,
  PASTE                => 112,
  UNIGRAMS             => 49,
  BIGRAMS              => 50,
  TRIGRAMS             => 51,
  QUADGRAMS            => 52,
  QUINTGRAMS           => 53,
);

enum GRAM is export (
  UNI   => 1,
  BI    => 2,
  TRI   => 3,
  QUAD  => 4,
  QUINT => 5,
);


#sub create-menu () {
#  my $menu;
#
#  $menu = GTK::Utils::MenuBuilder.new(:bar, TOP => [
#    File => [
#      'Open Cipher'   => { 'do' => -> { open-cipher-file  } },
#      'Save Cipher'   => { 'do' => -> { save-cipher-file  } },
#      '-'              => False,
#      Close            => { 'do' => -> { close-file         } },
#      Quit             => { 'do' => -> { quit               } },
#    ],
#    View => [
#      'Statusbar' => { :check, 'do' => -> { say 'toggled'         } },
#    ],
#  ]);
#
#  $menu;
#}

#sub create-statusbar () {
#  $!statusbar = GTK::Statusbar.new;

#}

