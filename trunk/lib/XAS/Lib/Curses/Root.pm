package XAS::Lib::Curses::Root;

my $mixin; 
BEGIN {
    $mixin = 'XAS::Lib::Curses::Unix';
    $mixin = 'XAS::Lib::Curses::Win32' if ($^O eq 'MSWin32');
}

use POE;
use Curses;
use POE::Component::Curses::MainLoop;

use XAS::Class
  debug   => 0,
  version => '0.01',
  base    => 'XAS::Base',
  mixin   => $mixin,
; 

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub key_handler {
    my ( $kernel, $heap, $keystroke ) = @_[ KERNEL, HEAP, ARG0 ];
 
    if ( $keystroke ne -1 ) {

        if ( $keystroke lt ' ' ) {

            $keystroke = '<' . uc( unctrl($keystroke) ) . '>';

        } elsif ( $keystroke =~ /^\d{2,}$/ ) {

            $keystroke = '<' . uc( keyname($keystroke) ) . '>';

        }

        if ( $keystroke eq '<KEY_RESIZE>' ) {
 
            # don't handle this here, it's handled in window_resize

            return;

        } elsif ( $keystroke eq '<KEY_MOUSE>' ) {
 
            # the mouse is handled differently depending on platform

            my ($id, $x, $y, $z, $bstate) = get_mouse_event();
            handle_mouse_event($id, $x, $y, $z, $bstate, $heap);

        } else {
 
            if ( $keystroke eq '<^L>' ) {

                $kernel->yield('window_resize');

            } elsif ( $keystroke eq '<^C>' ) {

                exit();

            } else {

                $heap->{mainloop}->event_key(
                    type => 'stroke',
                    key  => $keystroke,
                );

            }

        }

    }
    
}

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
    my $self = shift;
 
    my %params = $self->validate_params(@_, {
        alias => { default  => 'curses' },
        args  => { optional => 1, type => HASHREF }
    });
 
    # setup mainloop and root toolkit object

    my $mainloop = POE::Component::Curses::MainLoop->new(
        session_name => $params{alias},
        defined $params{args} ? ( args => $params{args} ) : ()
    );

    POE::Session->create(
        inline_states => {
            _start => sub {
                my ( $kernel, $session, $heap ) = @_[ KERNEL, SESSION, HEAP ];
                # give a name to the session
                $kernel->alias_set($params{alias});
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
 use Curses::Toolki::Widget::Window;
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
          ->signal_connect(clicked => sub { exit(0); })
      )
      ->set_coordinates( x1 => 0, y1 => 0, x2 => '100%', y2 => '100%')
 )

 POE:Kernel->run();

=head1 DESCRIPTION

This is an alternative event loop for the L<Curses::Toolkit|https://metacpan.org/pod/Curses::Toolkit>. I developed this 
when I decided to write curses based programs that would also run on Windows.

Curses::Toolkit has an external event loop that is based on POE, which uses
L<POE::Wheel::Curses|https://metacpan.org/pod/POE::Wheel::Curses>. This module uses select() to read STDIN. Windows 
doesn't support this, so an alternative was needed. The alternative was a 
polling POE task to read STDIN. While this will work on other platforms it 
is not optimal. So this module loads mixins to handle those alternatives. 

You can read L<XAS::Lib::Curses::Win32|XAS::Lib::Curses::Win32> for the gory details on how to get
Curses.pm to work correctly on Windows.

This module will allow all of the examples from Curses::Toolkit to run under
Windows. There are differences with color selection, which this module won't 
address.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

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
