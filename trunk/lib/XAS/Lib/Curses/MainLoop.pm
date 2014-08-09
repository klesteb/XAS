package XAS::Lib::Curses::MainLoop;

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
  base    => 'XAS::Base'
  vars => {
    PARAMS => {
      -session_name => 1,
      -args         => { optional => 1, default => {}, type => HASHREF }
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

    my %params = $self->validate_params(\@_, {   
        type => 1,
        key  => 1,
    });

    $params->{type} eq 'stroke' or return;

    my $event = Curses::Toolkit::Event::Key->new(
        type        => 'stroke',
        params      => { key => $params{key} },
        root_window => $self->get_toolkit_root,
    );

    $self->get_toolkit_root->dispatch_event($event);

    return;

}

sub event_mouse {
    my $self = shift;

    my %params = $self->validate_params(\@_, {   
        type   => 1,
        type2  => 1,
        button => 1,
        x      => 1,
        y      => 1,
        z      => 1,
    });

    $params{type} eq 'click' or return;
    $params{type} = delete $params{type2};

    $params{coordinates} = Curses::Toolkit::Object::Coordinates->new(
        x1 => $params{x},
        x2 => $params{x},
        y1 => $params{y},
        y2 => $params{y},
    );

    delete @params{qw(x y z)};

    my $event = Curses::Toolkit::Event::Mouse::Click->new( 
        %params, 
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

    my $self = $class->SUPER::(@_);

    $self->{redraw_needed} = 0;

    $self->{toolkit_root} = Curses::Toolkit->init_root_window( $self->args );
    $self->{toolkit_root}->set_mainloop($self);

    return $self;

}

1;

__END__

=head1 NAME

POE::Component::Curses::MainLoop - <FIXME>

=head1 VERSION

version 0.211

=head1 SYNOPSIS

This module is not for you !

You should not use this module directly. It's used by L<POE::Component::Curses>
as a MainLoop interface to L<Curses::Toolkit>

Please look at L<POE::Component::Curses>. Thanks !

=head1 AUTHOR

Damien "dams" Krotkine

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Damien "dams" Krotkine.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
