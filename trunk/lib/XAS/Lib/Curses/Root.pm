package XAS::Lib::Curses::Root;

my $mixin; 
BEGIN {
    $mixin = 'XAS::Lib::Curses::Unix';
    $mixin = 'XAS::Lib::Curses::Win32' if ($^O eq 'MSWin32');
}

use POE;
use Curses;

use XAS::Class
  debug   => 0,
  version => '0.01',
  base    => 'XAS::Base',
  mixin   => $mixin,
  vars => {
    PARAMS => {
      -interface => 1,
      -alias     => { optional => 1, default => 'curses' },
    }
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub pre_window_resize {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    # This is a hack : it seems the window resize is one event
    # late, so we issue an additional one a bit later

    $kernel->yield('window_resize');
    $kernel->delay( window_resize => 1 / 10 );

}

sub window_resize {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    $heap->{mainloop}->event_resize();

}

sub rebuild_all {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    $heap->{mainloop}->event_rebuild_all();

}
 
# Now the Mainloop signals

sub redraw {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    $heap->{mainloop}->event_redraw();

}

sub add_delay_handler {
    my $seconds = $_[ARG0];
    my $code    = $_[ARG1];

    $_[KERNEL]->delay_set( 'delay_handler', $seconds, $code, @_[ ARG2 .. $#_ ] );

}

sub delay_handler {
    my $code = $_[ARG0];

    $code->( @_[ ARG1 .. $#_ ] );

}

sub stack_event {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    $heap->{mainloop}->event_generic( @_[ ARG0 .. $#_ ] );

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    my $mainloop = $self->interface;

    # initialize POE, it does nothing, but does remove an
    # annoying error message if POE exits without creating any
    # sessions

    $poe_kernel->run();

    # set up the event loop

    POE::Session->create(
        inline_states => {
            _start => sub {
                my ( $kernel, $session, $heap ) = @_[ KERNEL, SESSION, HEAP ];
                # give a name to the session
                $kernel->alias_set($self->alias);
                # save the mainloop
                $heap->{mainloop} = $mainloop;
                # listen for window resize signals
                $kernel->sig( WINCH => 'pre_window_resize' );
                # start keyboard/mouse handler
                $kernel->yield('startup');
                # ask the mainloop to rebuild_all coordinates
                $kernel->yield('rebuild_all');
            },
            startup           => \&startup,
            keyin             => \&keyin,
            key_handler       => \&key_handler,
            pre_window_resize => \&pre_window_resize,
            window_resize     => \&window_resize,
            rebuild_all       => \&rebuild_all,
            redraw            => \&redraw,
            add_delay_handler => \&add_delay_handler,
            delay_handler     => \&delay_handler,
            stack_event       => \&stack_event,
        }
    );

    return $mainloop->get_toolkit_root();

}

1;

__END__

=head1 NAME

XAS::Lib::Curses::Root - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Lib::Curses::Root;
 use XAS::Lib::Curses::Toolkit;
 use Curses::Toolkit::Widget::Window;
 use Curses::Toolkit::Widget::Button;

 my $root = XAS::Lib::Curses::Root->new(
     -alias => 'curses',
     -interface => XAS::Lib::Curses::Toolkit->new(
         -session_name => 'curses',
         -args => {}
     )
 );

 $root->add_window(
    my $window = Curses::Toolkit::Widget::Window
      ->new()
      ->set_name('main_window')
      ->add_widget(
        my $button = Curses::Toolkit::Widget::Button
          ->new()
          ->set_name('my_button')
          ->signal_connect(clicked => sub { exit(0); })
      )
      ->set_coordinates( x1 => 0, y1 => 0, x2 => '100%', y2 => '100%')
 )

 POE:Kernel->run();

=head1 DESCRIPTION

This is an alternative event loop for the L<Curses::Toolkit|https://metacpan.org/pod/Curses::Toolkit>. 
I developed this when I decided to write curses based programs that would 
also run on Windows.

Curses::Toolkit has an external event loop that is based on POE, which uses
L<POE::Wheel::Curses|https://metacpan.org/pod/POE::Wheel::Curses>. This module 
uses select() to read STDIN. Windows doesn't support this, so an alternative 
was needed. The alternative was a polling POE task to read STDIN. While this 
will work on other platforms it is not optimal. So this module loads mixins 
to handle those alternatives.

You can read L<XAS::Lib::Curses::Win32|XAS::Lib::Curses::Win32> for the gory 
details on how to get Curses.pm to work correctly on Windows.

This module will allow all of the examples from Curses::Toolkit to run under
Windows. There are differences with color selection, which this module won't 
address.

=head1 METHODS

=head2 new

This does basic Curses intializations and setups keyboard, mouse and timer
handling. It also initializes the event loop, but doesn't start it. It returns
a handle to a presentaion manager, such as Curses::Toolkit. It takes the 
following parameters:

=over 4

=item B<-alias>

The alias for the POE session. Defaults to 'curses'.

=item B<-interface>

This is the interface module to the internal event loop. This is basically a 
callback mechanism between the event loop and the visual presentation. 
Please see L<XAS::Lib::Curses::Toolkit|XAS::Lib::Curses::Toolkit> as an example.

=back

=head2 pre_window_resize(KERNEL, HEAP)

A hack for when the terminal screen has been resized. 

=head2 window_resize(KERNEL, HEAP)

A callforward to event_resize() in the interface module.

=head2 rebuild_all(KERNEL, HEAP)

A callforward to event_rebuild_all() in the interface module.

=head2 redraw(KERNEL, HEAP)

A callforward to event_redraw() in the interface module.

=head2 add_delay_handler(KERNEL, ARG0, ARG1)

A callback from the interface module to add a delay handler.

=head2 delay_handler(ARG0, ARG1, ...)

A callback from the interface module to execute a delay handler.

=head2 stack_event(KERNEL, HEAP)

A callforward to the interface module to event_generic().

=head1 MIXINS

Mixins are provided to handle the differnces between Curses implementations.
The currently provided ones are for Unix and Win32. They provide this methods.

=head2 startup(KERNEL, HEAP, SESSION)

This method performs basic Curses initialization and keyin() polling if needed.

=head2 keyin(KERNEL)

Read the keyboard and mouse.

=head2 key_hanlder(KERNEL, HEAP, ARG0)

Read and process keyboard and mouse events.

=head2 get_mouse_event

Platform specific handling of mouse events. 

=head2 handle_mouse_event

Platform specific handling of the mouse events.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=item L<XAS::Lib::Curses::Unix|XAS::Lib::Curses::Unix>

=item L<XAS::Lib::Curses::Win32|XAS::Lib::Curses::Win32>

=item L<Curses::Toolkit|https://metacpan.org/pod/Curses::Toolkit>

=item L<POE::Component::Curses|https://metacpan.org/pod/POE::Component::Curses>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See L<http://dev.perl.org/licenses/> for more information.

=cut
