unit module Z::Cipher::Util;

enum COMMAND is export (
  VFLIP      => 70,
  HFLIP      => 102,
  AROTATE    => 82,
  CROTATE    => 114,
  TRANSPOSE  => 116,
  VMIRROR    => 77,
  HMIRROR    => 109,
  CANGLE     => 65,
  AANGLE     => 97,
  CHANGE     => 99,
  UNIGRAMS   => 49,
  BIGRAMS    => 50,
  TRIGRAMS   => 51,
  QUADGRAMS  => 52,
  QUINTGRAMS => 53,
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

