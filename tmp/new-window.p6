use GTK::Application;
use GTK::Window;
use GTK::Box;
use GTK::Button;
use GTK::Raw::Types;

my $app = GTK::Application.new(
  title  => 'org.genex.test.widget',
  width  => 400,
  height => 400
);

my GTK::Button $new-win .= new_with_label: <new-win>;

$new-win.clicked.tap: { new-win };

$app.activate.tap({
my $box = GTK::Box.new-vbox(6);

$box.pack_start($new-win, False, True, 0);

$app.window.add: $box;
$app.show_all;
});

$app.run;

sub new-win () {
	my GTK::Window $window .= new: GTK_WINDOW_TOPLEVEL, :title<NewWin>;
	$app.add_window: $window;
  $window.show;
}
