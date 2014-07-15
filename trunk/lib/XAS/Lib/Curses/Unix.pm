package XAS::Lib::Curses::Unix;

our $VERSION = '0.01';

use POE;
use Curses;
use POE::Wheel::Curses;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  mixins  => 'startup keyin get_mouse_event handle_mouse_event',
;

my @button_events = qw(
    BUTTON1_PRESSED BUTTON1_RELEASED BUTTON1_CLICKED
    BUTTON1_DOUBLE_CLICKED BUTTON1_TRIPLE_CLICKED
    BUTTON2_PRESSED BUTTON2_RELEASED BUTTON2_CLICKED
    BUTTON2_DOUBLE_CLICKED BUTTON2_TRIPLE_CLICKED
    BUTTON3_PRESSED BUTTON3_RELEASED BUTTON3_CLICKED
    BUTTON3_DOUBLE_CLICKED BUTTON3_TRIPLE_CLICKED
    BUTTON4_PRESSED BUTTON4_RELEASED BUTTON4_CLICKED
    BUTTON4_DOUBLE_CLICKED BUTTON4_TRIPLE_CLICKED
    BUTTON5_PRESSED BUTTON5_RELEASED
    BUTTON5_CLICKED BUTTON5_DOUBLE_CLICKED BUTTON5_TRIPLE_CLICKED
    BUTTON_SHIFT BUTTON_CTRL BUTTON_ALT
);

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub startup {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    # now listen to the keys
    $heap->{console} = POE::Wheel::Curses->new(
        InputEvent => 'key_handler',
    );

}

sub keyin {
    my ($kernel) = $_[KERNEL];

}

sub get_mouse_event {

    my $mouse_curses_event = 0;

    getmouse($mouse_curses_event);

    # $mouse_curses_event is a struct. From curses.h (note: this might change!):
    #
    # typedef struct
    # {
    #    short id;           /* ID to distinguish multiple devices */
    #        int x, y, z;        /* event coordinates (character-cell) */
    #        mmask_t bstate;     /* button state bits */
    # } MEVENT;
    #
    # ---------------
    # s signed short
    # x null byte
    # x null byte
    # ---------------
    # i integer
    # ---------------
    # i integer
    # ---------------
    # i integer
    # ---------------
    # l long
    # ---------------

    my ($id, $x, $y, $z, $bstate) = unpack( "sx2i3l", $mouse_curses_event );

    return ($id, $x, $y, $z, $bstate);

}

sub handle_mouse_event {
    my ( $id, $x, $y, $z, $bstate, $heap ) = @_;

    foreach my $possible_event_name (@button_events) {

        my $possible_event = eval($possible_event_name);

        if ( !$@ && $bstate == $possible_event ) {

            my ($button, $type2) = $possible_event_name =~ /^([^_]+)_(.+)$/;

            $heap->{mainloop}->event_mouse(
                type   => 'click',
                type2  => lc($type2),
                button => lc($button),
                x      => $x,
                y      => $y,
                z      => $z,
            );

        }

    }

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Curses::Unix - A mixin class for Curses on Unix

=head1 DESCRIPTION

This is the mixin class for working with Curses on Linux\Unix.

=head1 METHODS

In the following methods: $kernel, $session and $heap are standard variables
from POE.

=head2 startup($kernel, $session, $heap)

This will initialize the screen and keyboard.

=head2 keyin($kernel)

This does nothing.

=head2 get_mouse_event

This will parse the mouse eventx and return the following variables.

=over 4

=item $id

This is the id of the event, this is always 0.

=item $x

The position of the mouse on the X axis of the screen.

=item $y 

The position of the mouse on the Y axis of the screen.

=item $z 

Not, sure, but it is always 0.

=item $bstate

The state of the mouse.

=back

=head2 handle_mounse_event($id, $x, $y, $z, $bstate, $heap)

This will take $id, $x, $y, $z, $bstate and $heap variable and create 
the appropriate event to dispatch within Curses::Toolkit.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=item L<Curses::Toolkit|https://metacpan.org/pod/Curses::Toolkit>

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
