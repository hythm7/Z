use GTK::Simple;
use GTK::Simple::App;

unit class Z;
  also is GTK::Simple::App;
  


submethod BUILD () {
my \a = GTK::Simple::Button.new(label => "a");
	self.set-content(
			GTK::Simple::Grid.new(

					[0, 0, 1, 1] => my $tlb = GTK::Simple::Button.new(label => "up left"),
					[1, 0, 1, 1] => my $trb = GTK::Simple::Button.new(label => "up right"),

					[0, 2, 1, 1] => my $blb = GTK::Simple::ToggleButton.new(label => "bottom left"),
					[1, 2, 1, 1] => my $brb = GTK::Simple::ToggleButton.new(label => "bottom right"),
			)
	);

	self.border-width = 20;
}


