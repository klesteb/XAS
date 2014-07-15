package XAS::Lib::Curses::Win32;

our $VERSION = '0.01';

use POE;
use Curses;

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
);

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub startup {
    my ( $kernel, $session, $heap ) = @_[ KERNEL, SESSION, HEAP ];

    my $junk = 0;
    my $event = ALL_MOUSE_EVENTS;

    initscr();

    if (has_color()) {

        start_color();

    }

    cbreak();
    raw();
    noecho();
    nonl();
  
    keypad(1);
    intrflush(0);
    meta(1);
    typeahead(-1);
    curs_set(0);                # these seems to be needed on PDCurses

    nodelay(1);                 # set terminal input to non blocking
    timeout(0);

    mousemask($event, $junk);   # turn the mouse on
    mouseinterval(10);          # this seems to give a good response

    clear();
    refresh();

    $kernel->yield('keyin');    # Start keystroke polling

}

sub keyin {
    my ($kernel) = $_[KERNEL];
 
    while ((my $keystroke = Curses::getch) ne '-1') {

        $kernel->yield('key_handler', $keystroke);

    }

    $kernel->delay('keyin', 0.1); 

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
    my ($id, $x, $y, $z, $bstate, $heap) = @_;
    
    foreach my $possible_event_name (@button_events) {

        my $possible_event = eval($possible_event_name);

        if ( !$@ && $bstate == $possible_event ) {

            my ($button, $type2) = $possible_event_name =~ /^([^_]+)_(.+)$/;

            # no matter what the mouseinterval() setting is, PDCurses
            # always returned "BUTTON_PRESSED", so we are fudging here.

            $type2 = 'CLICKED' if ($type2 eq 'PRESSED');

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

XAS::Lib::Curses::Win32 - A mixin for handling PDCurses issues on Win32

=head1 DESCRIPTION

Who in there right minds would want to run Curses on Windows? I guess I did.
To start with you need to download and install PDCurses. You can get that 
here:

  http://sourceforge.net/projects/pdcurses/files/pdcurses/3.4/

You want the pdc34dllw.zip file. This is compatible with current release of
Curses.pm. The package from the GnuWin32 site is not. To install, do the 
following:

 1) Unpack the zip archive.

 2) Copy the .h files to \strawberry\c\include

 3) Copy the .lib file to \strawberry\c\lib

 4) copy the .dll file to \strawberry\c\bin

That's it, PDCurses is now installed. Now for the fun part. Actually making it 
work correctly with Curses.pm. Start by downloading it from CPAN. Do
not do a default install.

Curses.pm is designed to be used with Ncurses. Which is a standard 
install on most Linuxes and some Unixes. PDCurses is "compatible" with
Ncurses, with the exception of the mouse handling functions. 

PDCurses supports the Ncurses mouse handling and an older set of
SYSV mouse handling routines. The problem lies with the getmouse() call. 
This is a name clash with the Ncurses routine of the same name. PDCurses 
solves this by providing a nc_getmouse() call. Curses.pm doesn't check for 
this function, only getmouse() which exists, but has a different call 
interface. So the mouse doesn't work.

To fix this problem you need to edit some files. Start with list.syms and add
the following line around the getmouse(0) line.

"E  nc_getmouse(0)"

Next change some code in CursesFun.c. Replace the original code for the 
XS_Curses_getmouse with this:

 XS(XS_Curses_getmouse)
 {
     dXSARGS;
 #ifdef C_GETMOUSE
     c_exactargs("getmouse", items, 1);
     {
     MEVENT *event   = (MEVENT *)sv_grow(ST(0), 2 * sizeof(MEVENT));
     int ret = getmouse(event);
     c_setmevent(ST(0));
     ST(0) = sv_newmortal();
     sv_setiv(ST(0), (IV)ret);
     }
     XSRETURN(1);
 #elif defined C_NC_GETMOUSE
     c_exactargs("getmouse", items, 1);
     {
     MEVENT *event   = (MEVENT *)sv_grow(ST(0), 2 * sizeof(MEVENT));
     int ret = nc_getmouse(event);
     c_setmevent(ST(0));
     ST(0) = sv_newmortal();
     sv_setiv(ST(0), (IV)ret);
     }
     XSRETURN(1);
 #else
     c_fun_not_there("getmouse");
     XSRETURN(0);
 #endif
 }

This will allow Curses.pm to access the correct getmouse() function call. Now
you need to build Curses.pm. You do this in the usually fashion.

 > perl Makefile.PL PANELS
 > dmake
 > dmake test
 > dmake install

 Note: You need the "PANELS" qualifier. Curses.pm will build without it, but it
 will automatically find the panel routines in PDCurses. Doing so, without the
 qualifier, will cause Perl to crash.

At this point, you have a fully functional curses on Windows.

=head1 METHODS

In the following methods: $kernel, $session, $heap are standard variables
from POE.

=head2 startup($kernel, $session, $heap)

This will initialize the screen, keyboard and turn on mouse handling. It 
will also start the polling task for getch().

=head2 keyin($kernel)

Read the keyboard with getch() and reschedule the poll.

=head2 get_mouse_event

The will parse the mouse event and return the following variables.

=over 4

=item $id

This is the id of the event, this is always 0.

=item $x

The position of the mouse on the X plain of the screen.

=item $y 

The position of the mouse on the Y plain of the screen.

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
