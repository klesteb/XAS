package WPM::Lib::Curses::Win32 ;

our $VERSION = '0.01';

use POE;
use Curses;
use Params::Validate qw(SCALAR ARRAYREF HASHREF CODEREF GLOB GLOBREF SCALARREF HANDLE BOOLEAN UNDEF validate validate_pos);

use WPM::Class
  version => $VERSION,
  base    => 'WPM::Base',
  mixins  => 'startup keyin key_handler @button_events',
;

Params::Validate::validation_options(
    on_fail => sub {
        my $params = shift;
        my $class  = __PACKAGE__;
        WPM::Base::validation_exception($params, $class);
    }
);

our @button_events = qw(
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
    start_color();
 
    cbreak();
    raw();
    noecho();
    nonl();
  
    keypad(1);
    intrflush(0);
    meta(1);
    typeahead(-1);
    curs_set(0);

     # set terminal input to non blocking

    nodelay(1);
    timeout(0);

    # turn the mouse on.

    mousemask($event, $junk);
    
    clear();
    refresh();

    # Start keystroke polling
    $kernel->yield('keyin');

}

sub keyin {
    my ($kernel) = $_[KERNEL];
 
    while ((my $keystroke = Curses::getch) ne '-1') {

        $kernel->yield('key_handler', $keystroke);

    }

    $kernel->delay('keyin', 0.1); 

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

WPM::Lib::Curses::Win32 - A mixin for handling Curses issues on Win32

=head1 SYNOPSIS

 use WPM::XXX;

=head1 DESCRIPTION

=head1 METHODS

=head2 method1

=head1 SEE ALSO

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See L<http://dev.perl.org/licenses/> for more information.

=cut
