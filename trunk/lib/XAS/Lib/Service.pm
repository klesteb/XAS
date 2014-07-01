package XAS::Lib::Service;

our $VERSION = '0.03';

use POE;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Lib::Session',
  vars => {
    PARAMS => {
      -alias => { optional => 1, default => 'service' }
    }
  }
;

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub session_initialize {
    my $self = shift;

    $poe_kernel->state('session_idle',   $self, '_session_idle');
    $poe_kernel->state('session_pause',  $self, '_session_pause');
    $poe_kernel->state('session_resume', $self, '_session_resume');
    $poe_kernel->state('session_status', $self, '_session_status');

    $poe_kernel->sig('HUP', 'session_interrupt');

}

sub session_idle {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: session_idle()");

}

sub session_pause {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: session_pause()");

}

sub session_resume {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: session_resume()");

}

sub session_status {
    my $self   = shift;
    my $status = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: session_status()");

    $self->{'__status'} = $status if (defined($status));

    return $self->{'__status'};

}

# ----------------------------------------------------------------------
# Public Accessors
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _session_init {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: _session_init()");

    $self->session_initialize();

}

sub _session_idle {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: session_idle()");

    $self->session_idle();

}

sub _session_pause {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: session_pause()");

    $self->session_pause();

}

sub _session_resume {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: _session_resume()");

    $self->session_resume();

}

sub _session_status {
    my ($self, $status) = @_[OBJECT, ARG0];

    my $alias = $self->alias;

    $self->log->debug("$alias: _session_status()");

    $self->session_status($status);

}

1;

__END__

=head1 NAME

XAS::Lib::Service - The base class for all POE Sessions.

=head1 SYNOPSIS

 my $session = XAS::Lib::Session->new(
     -alias => 'name',
 );

=head1 DESCRIPTION

This module provides an object based POE session. This object will perform
the necessary actions for the lifetime of the session. This includes handling
signals. The following signals INT, TERM, QUIT will trigger the 'shutdown'
event which invokes the session_cleanup() method. The HUP signal will invoke 
the session_reload() method. This module inherits from XAS::Base.

=head1 METHODS

=head2 session_initialize

This is where the session should do whatever initialization it needs. This
initialization may include defining additional events.

=head2 session_shutdown

This method should perform cleanup actions for the session. This is triggered
by a "shutdown" event.

=head2 session_reload

This method should perform reload actions for the session. By default it
calls $kernel->sig_handled() which terminates further handling of the HUP
signal.

=head2 session_stop

This method should perform stop actions for the session. This is triggered
by a "_stop" event.

=head1 PUBLIC EVENTS

The following public events are defined for the session.

=head2 session_startup

This event should start whatever processing the session will do. It is passed
two parameters:

=head2 session_shutdown

When you send this event to the session, it will invoke the session_cleanup() 
method.

=head1 PRIVATE EVENTS

The following events are used internally:

 session_init
 session_interrupt
 session_reload
 shutdown

They should only be used with caution.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

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
