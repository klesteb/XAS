package XAS::Lib::Service::Win32;

our $VERSION = '0.01';

use POE;
use Win32::Daemon;

use XAS::Class
  version  => $VERSION,
  base     => 'XAS::Base',
  debug    => 0,
  mixins   => 'initialize _current_state
               SERVICE_START_PENDING
               SERVICE_STOP_PENDING SERVICE_PAUSE_PENDING
               SERVICE_CONTINUE_PENDING SERVICE_CONTROL_SHUTDOWN
               SERVICE_RUNNING SERVICE_STOPPED SERVICE_PAUSED'
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

sub session_initialize {
    my ($self, $kernel, $session) = @_;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering intialize()");

    $kernel->state('poll', $self, '_poll');

    $self->last_state(SERVICE_START_PENDING);

    unless (Win32::Daemon::StartService()) {

        $self->throw_msg(
            'xas.lib.service.win32.startup.startservice',
            'noservice',
            $self->_get_error()
        );

    }

    $kernel->call('poll');

    $self->SUPER::session_initialize($kernel, $session);

    $self->log->debug("$alias: leaving intialize()");

}

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

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

        Win32::Daemon::State($state, $delay);

    }

    return Win32::Daemon::State();

}

1;

__END__

=head1 NAME

XAS::Lib::Service::Win32 - A mixin class for Win32 Services

=head1 SYNOPSIS

 use XAS::Lib::Service;

 my $sevice = XAS::Lib::Service->new(
    -alias             => 'session',
    -poll_interval     => 2,
    -shutdown_interval => 25
 );

=head1 DESCRIPTION

This module is a mixin that provides an interface between the Win32 SCM and
POE sessions. It allows POE to manage the scheduling of sessions while
referencing the Win32 SCM event stream.

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

Copyright (C) 2013 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
