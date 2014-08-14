package XAS::Lib::Curses::Toolkit;

our $VERSION = '0.01';

use POE;
use Curses::Toolkit;
use Params::Validate 'HASHREF';
use Curses::Toolkit::Event::Key;
use Curses::Toolkit::Event::Shape;
use Curses::Toolkit::Event::Mouse::Click;
use Curses::Toolkit::Object::Coordinates;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  vars => {
    PARAMS => {
      -session_name => { optional => 1, default => 'curses' },
      -args         => { optional => 1, default => {}, type => HASHREF },
    }
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub get_session_name { $_[0]->{session_name}; }
sub set_session_name { $_[0]->{session_name} = $_[1]; $_[0]; }

sub get_args { $_[0]->{args}; }
sub get_toolkit_root { $_[0]->{toolkit_root}; }
sub get_redraw_needed { $_[0]->{redraw_needed}; }
sub set_redraw_needed { $_[0]->{redraw_needed} = $_[1]; $_[0]; }

sub needs_redraw {
    my $self = shift;

    # if redraw is already stacked, just quit

    $self->get_redraw_needed and return;

    $self->set_redraw_needed(1);
    $poe_kernel->post($self->get_session_name, 'redraw');

    return $self;

}

sub add_delay {
    my $self    = shift;
    my $seconds = shift;
    my $code    = shift;

    $poe_kernel->call($self->get_session_name, 'add_delay_handler', $seconds, $code, @_ );

    return;

}

sub stack_event {
    my $self = shift;

    $poe_kernel->post($self->get_session_name, 'stack_event', @_);

    return;

}

sub event_rebuild_all {
    my $self = shift;

    $self->get_toolkit_root->_rebuild_all();

    return;

}

sub event_redraw {
    my $self = shift;

    # unset this early so that redraw requests that may appear in the meantime will
    # be granted

    $self->set_redraw_needed(0);

    $self->get_toolkit_root->render();
    $self->get_toolkit_root->display();

    return;

}

sub event_resize {
    my $self = shift;

    my $event = Curses::Toolkit::Event::Shape->new(
        type        => 'change',
        root_window => $self->get_toolkit_root
    );

    $self->get_toolkit_root->dispatch_event($event);

    return;

}

sub event_key {
    my $self = shift;

    my $params = $self->validate_params(\@_, {   
        type => 1,
        key  => 1,
    });

    $params->{type} eq 'stroke' or return;

    my $event = Curses::Toolkit::Event::Key->new(
        type        => 'stroke',
        params      => { key => $params->{key} },
        root_window => $self->get_toolkit_root,
    );

    $self->get_toolkit_root->dispatch_event($event);

    return;

}

sub event_mouse {
    my $self = shift;

    my $params = $self->validate_params(\@_, {   
        type   => 1,
        type2  => 1,
        button => 1,
        x      => 1,
        y      => 1,
        z      => 1,
    });

    $params->{type} eq 'click' or return;
    $params->{type} = delete $params->{type2};

    $params->{coordinates} = Curses::Toolkit::Object::Coordinates->new(
        x1 => $params->{x},
        x2 => $params->{x},
        y1 => $params->{y},
        y2 => $params->{y},
    );

    delete $params->{x};
    delete $params->{y};
    delete $params->{z};

    my $event = Curses::Toolkit::Event::Mouse::Click->new( 
        %$params, 
        root_window => $self->get_toolkit_root 
    );

    $self->get_toolkit_root->dispatch_event($event);

    return;

}

sub event_generic {
    my $self = shift;

    $self->get_toolkit_root->dispatch_event(@_);

    return;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{redraw_needed} = 0;

    $self->{toolkit_root} = Curses::Toolkit->init_root_window( $self->args );
    $self->{toolkit_root}->set_mainloop($self);

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Curses::Toolkit - A class for the XAS environment

=head1 SYNOPSIS

 use POE;
 use XAS::Lib::Curses::Root;
 use XAS::Lib::Curses::Toolkit;

 my $root = XAS::Lib::Curses::Root->new(
     -interface => XAS::Lib::Curses::Toolkit->new(
         -session_name => 'curses',
         -args => {}
     )
 );

 $root->add_window(...);

 POE::Kernel->run();

=head1 DESCRIPTION

This is the interface module between the event loop provided by 
L<XAS::Lib::Curses::Root|XAS::Lib::Curses::Root> and the Curses::Toolkit. 

=head1 METHODS

=head2 new

This method initializes the interface. It takes the following parameters:

=over 4

=item B<-session_name>

The session name of the event loop. Defaults to 'curses'.

=item B<-args>

An optional set of args to pass to the Curses::Toolkit.

=back

=head2 get_session_name

Returns the session name of the event loop.

=head2 set_session_name($name)

Sets the session name of the event loop. Not very useful as it dosen't actually
change the event loops session name.

=head2 get_toolkit_root

Returns a handle to the Curses::Toolkit.

=head2 get_redraw_needed

Returns wither a redraw is needed.

=head2 set_redraw_needed

Toggles wither a redraw is needed.

=head2 redraw_needed

A callback to the event loop to issue a 'redraw' event.

=head2 add_delay

A callback to the event loop to add a delay handler.

=head2 stack_event

A callback to the event loop to issue a 'stack_event' event.

=head2 event_rebuild_all

A callforward from the event loop to rebuild the screen.

=head2 event_redraw

A callforward from the event loop to redraw the screen.

=head2 event_resize

A callforward from the event loop that the screen has been resized. 

=head2 event_key(type => '', key => '')

A callforward when a key has been pressed.

=over 4

=item B<type>

The event type. Should be 'stroke'.

=item B<key>

The key that was pressed.

=back

=head2 event_mouse(type => '', type2 => '', button => '', x => '', y => '', z =>'')

A callforward from the event loop for when the mouse has been used.

The named parameters are what is returned by the Curses getmouse() function.

=head2 event_generic(@_)

A callforward from the event loop for a generic event. 

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
