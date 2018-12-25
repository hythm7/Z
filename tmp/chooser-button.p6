use GTK::Application;
use GTK::Box;
use GTK::Button;
use GTK::FileChooserButton;

my $app = GTK::Application.new(
  title  => 'org.genex.test.widget',
  width  => 400,
  height => 400
);

my GTK::Button $exit .= new_with_label: <exit>;
my GTK::FileChooserButton $chooser .= new: :title('Z'), :action(0);
$chooser.show;

$exit.clicked.tap: { $app.exit  };
 $chooser.widget.file-activated.tap: { say $chooser.filename }; # What is the correct syntax?

$app.activate.tap({
my $box = GTK::Box.new-vbox(6);

$box.pack_start($chooser, False, True, 0);
$box.pack_start($exit, False, True, 0);

$app.window.add: $box;
$app.show_all;
});

$app.run;
