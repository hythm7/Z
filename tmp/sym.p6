#!/usr/bin/env perl6

use GTK::Raw::Types;
use GTK::Compat::Types;
use GTK::Application;
use GTK::FlowBox;
use GTK::Label;
use GTK::Button;
use GTK::Box;

my $app = GTK::Application.new(
  title  => 'org.genex.test.widget',
  width  => 400,
  height => 400
);

$app.activate.tap({
  CATCH { default { .message.say; $app.exit } }

  my GTK::Button $exit .= new_with_label: <exit>;
  $exit.clicked.tap: { $app.exit  };

  my $str = qq:to/END/;
  { ('a' .. 'z').pick( * ).join }
  { ('a' .. 'z').pick( * ).join }
  { ('a' .. 'z').pick( * ).join }
  { ('a' .. 'z').pick( * ).join }
  { ('a' .. 'z').pick( * ).join }
  END

  my $flowbox = GTK::FlowBox.new;

  $flowbox.halign = GTK_ALIGN_START;
  $flowbox.valign = GTK_ALIGN_START;
  $flowbox.homogeneous = True;
  $flowbox.selection-mode = GTK_SELECTION_MULTIPLE;
  $flowbox.min_children_per_line = 26;
  $flowbox.max_children_per_line = 26;
  $flowbox.activate-on-single-click = False;

  $flowbox.child-activated.tap( -> ( $f, $c, $p, $r ) {
    my $sym   = $f.get-selected-children.head.get-child.label;
    my @child = $f.get-children.grep({ .get-child.label ~~ $sym });

    @child.map( -> $child { $f.select-child: $child } );

  } );




  for $str.words.join.comb -> $sym {
    my $child = GTK::FlowBoxChild.new;
    #$child.add-events: GDK_BUTTON_PRESS_MASK;
    $child.add: GTK::Label.new: $sym;
    $flowbox.add: $child;
  }

  my $box = GTK::Box.new-vbox();
  $box.pack_start($flowbox, False, False, 0);
  $box.pack_start($exit, False, False, 0);

  $app.window.add: $box;
  $app.show_all;

});

$app.run;


# For this example to work I made changes to Flowbox.pm6 ( Diff below )

# 8  use GTK::Roles::Orientable;
# 9 +use GTK::Roles::Signals::FlowBox;

# 16    also does GTK::Roles::Orientable;
# 17 +  also does GTK::Roles::Signals::FlowBox;

# 34 -    my $to-be-selected = self!resolve-selected-child;
# 35 +    my $to-be-selected = self!resolve-selected-child($child);

# 43 -    my $to-be-unselected = self!resolve-selected-child;
# 44 +    my $to-be-unselected = self!resolve-selected-child($child);



