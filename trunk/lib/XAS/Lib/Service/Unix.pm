package XAS::Lib::Service::Unix;

our $VERSION = '0.01';

use POE;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  constant => {
    SERVICE_START_PENDING    => 1,
    SERVICE_STOP_PENDING     => 2,
    SERVICE_PAUSE_PENDING    => 3,
    SERVICE_CONTINUE_PENDING => 4,
    SERVICE_CONTROL_SHUTDOWN => 5,
    SERVICE_RUNNING          => 6,
    SERVICE_STOPPED          => 7,
    SERVICE_PAUSED           => 8,
  },
  mixins  => 'initialize _current_state _session_interrupt
              SERVICE_START_PENDING SERVICE_STOP_PENDING
              SERVICE_PAUSE_PENDING SERVICE_CONTINUE_PENDING
              SERVICE_CONTROL_SHUTDOWN SERVICE_RUNNING
              SERVICE_STOPPED SERVICE_PAUSED',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Overridden Methods - semi public
# ----------------------------------------------------------------------

sub sesion_initialize {
    my ($self, $kernel, $session) = @_;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_initialise()");

    $kernel->state('poll', $self, '_poll');

    $kernel->sig(CONT => 'session_interrupt');
    $kernel->sig(TSTP => 'session_interrupt');

    $self->last_state(SERVICE_START_PENDING);
    $self->_current_state(SERVICE_START_PENDING);

    $kernel->call('poll');

    $self->SUPER::session_initialize($kernel, $session);

    $self->log->debug("$alias: leaving session_initialise()");

}

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _session_interrupt {
    my ($kernel, $self, $session, $signal) = @_[KERNEL,OBJECT,SESSION,ARG0];

    my $alias = $self->alias;

    $self->log->debug("$alias: _session_interrupt()");

    if ($signal eq 'HUP') {

        $self->session_reload($kernel, $session);

    } elsif ($signal eq 'CONT') {

        $kernel->sig_handled();
        $self->_current_state(SERVICE_CONTINUE_PENDING);

    } elsif ($signal eq 'TSTP') {

        $kernel->sig_handled();
        $self->_current_state(SERVICE_STOP_PENDING);

    } else {

        $self->session_cleanup($kernel, $session);

    }

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _current_state {
    my $self = shift;
    my ($state, $delay) = $self->validate_params(\@_, [
        { optional => 1, default => undef },
        { optional => 1, default => 0 },
    ]);

    if (defined($state)) {

        $self->{state} = $state;

    }

    return $self->{state};

}

1;

__END__

=head1 NAME

XAS::Lib::Service::Unix - A mixin class for Unix Services

=head1 SYNOPSIS

 use XAS::Lib::Service;

 my $sevice = XAS::Lib::Service->new(
    -alias             => 'session',
    -poll_interval     => 2,
    -shutdown_interval => 25
 );

=head1 DESCRIPTION

This module is a mixin that provides an interface between a process supervisor
and POE sessions. It allows POE to manage the scheduling of sessions while
referencing Unix signals for process job control.

=head1 METHODS

=head2 new()

This method is used to initialize the service. It takes the following
parameters:

=over 4

=item B<-alias>

The name of this POE session.

=item B<-poll_interval>

This is the interval were the SCM sends SERVICE_RUNNING message. The
default is every 2 seconds.

=item B<-shutdown_interval>

This is the interval to pause the system shutdown so that the service
can cleanup after itself. The default is 25 seconds.

=back

It also use parameters from XAS::Lib::Session.

=head2 service_startup()

This method should be overridden, it is called when the service is
starting up.

=head2 service_shutdown()

This method should be overridden, it is called when the service has
been stopped or when the system is shutting down.

=head2 service_idle()

This method should be overridden, it is called every B<--poll_interval>.
This is where the work of the service can be done.

=head2 service_paused()

This method should be overridden, it is called when the service has been
paused.

=head2 service_unpaused()

This method should be overridden, it is called when the service has been
resumed.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
