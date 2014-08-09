
use lib '../lib';
use lib '/home/kevin/dev/XAS/trunk/lib';

use POE;
use XAS::Lib::Curses::Root;
use Curses::Toolkit::Widget::Window;
use Curses::Toolkit::Widget::Button;

my $root = XAS::Lib::Curses::Root->new();
$root->add_window(
    my $window = Curses::Toolkit::Widget::Window
      ->new()
      ->set_name('main_window')
      ->add_widget(
        my $button = Curses::Toolkit::Widget::Button
          ->new()
          ->set_name('my_button')
          ->set_text("Click to Exit")
          ->signal_connect(clicked => sub { exit(0); })
      )
      ->set_coordinates( x1 => 0, y1 => 0, x2 => '100%', y2 => '100%')
);

POE::Kernel->run();
 