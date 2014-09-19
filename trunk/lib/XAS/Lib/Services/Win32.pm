package XAS::Lib::Services::Win32;

our $VERSION = '0.01';

use POE;
use Win32;
use Win32::Daemon;

use XAS::Class
  debug    => 0,
  version  => $VERSION,
  base     => 'XAS::Base',
  mixins   => 'init_service _current_state poll
               SERVICE_START_PENDING
               SERVICE_STOP_PENDING SERVICE_PAUSE_PENDING
               SERVICE_CONTINUE_PENDING SERVICE_CONTROL_SHUTDOWN
               SERVICE_RUNNING SERVICE_STOPPED SERVICE_PAUSED'
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub init_service {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering init_service() - win32");

    unless (Win32::Daemon::StartService()) {

        $self->throw_msg(
            'xas.lib.service.win32.startup.startservice',
            'noservice',
            _get_error()
        );

    }

    $self->log->debug("$alias: leaving init_service() - win32");

}

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub poll {
    my ($self) = $_[OBJECT];

    my $stat;
    my $alias = $self->alias;
    my $delay = $self->poll_interval;
    my $state = $self->_current_state();

    $self->log->debug("$alias: entering _poll()");
    $self->log->debug("$alias: state = $state");

    if ($state == SERVICE_START_PENDING) {

        $self->log->debug("$alias: state = SERVICE_START_PENDING");

        # Initialization code

        $self->last_state(SERVICE_START_PENDING);
        $self->_current_state(SERVICE_START_PENDING, 6000);

        # Initialization code
        # ...do whatever you need to do to start...

        $self->_service_startup();
        $self->last_state(SERVICE_RUNNING);

    } elsif ($state == SERVICE_STOP_PENDING) {

        $self->log->debug("$alias: state = SERVICE_STOP_PENDING");

        # Stopping...

        $self->last_state(SERVICE_STOPPED);

    } elsif ($state == SERVICE_PAUSE_PENDING) {

        $self->log->debug("$alias: state = SERVICE_PAUSE_PENDING");

        # Pausing...

        $self->_service_paused();
        $self->last_state(SERVICE_PAUSED);

    } elsif ($state == SERVICE_CONTINUE_PENDING) {

        $self->log->debug("alias: state = SERVICE_CONTINUE_PENDING");

        # Resuming...

        if ($self->last_state == SERVICE_PAUSED) {

            $self->_service_resumed();
            $self->last_state(SERVICE_RUNNING);

        } else {

            $self->log->info_msg('unpaused');

        }

    } elsif ($state == SERVICE_RUNNING) {

        $self->log->debug("$alias: state = SERVICE_RUNNING");

        # Running...
        #
        # Note that here you want to check that the state
        # is indeed SERVICE_RUNNING. Even though the Running
        # callback is called it could have done so before
        # calling the "Start" callback.
        #

        if ($self->last_state == SERVICE_RUNNING) {

            $self->_service_idle();
            $self->last_state(SERVICE_RUNNING);

        }

    } elsif ($state == SERVICE_STOPPED) {

        $self->log->debug("$alias: state = SERVICE_STOPPED");

        # stopped...

        $delay = 0;
        $self->_service_shutdown();
        $self->last_state(SERVICE_STOPPED);

    } elsif ($state == SERVICE_CONTROL_SHUTDOWN) {

        $self->log->debug("$alias: state = SERVICE_CONTROL_SHUTDOWN");

        # shutdown...

        $self->_service_shutdown();
        $delay = $self->shutdown_interval;
        $self->last_state(SERVICE_STOP_PENDING);

    }

    # tell the SCM what is going on

    $self->_current_state($self->last_state, $delay);

    # queue the next polling interval

    unless ($delay == 0) {

        $stat = $poe_kernel->delay('poll', $delay);
        $self->log->error("unable to queue delay - $stat") if ($stat != 0);

    }

    $self->log->debug("$alias: leaving _poll()");

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _get_error {

    return(Win32::FormatMessage(Win32::Daemon::GetLastError()));

}

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

XAS::Lib::Services::Win32 - A mixin class for Win32 Services

=head1 DESCRIPTION

This module is a mixin that provides an interface between Services and 
the Win32 SCM. It allows POE to manage the scheduling of sessions while
referencing the Win32 SCM event stream.

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
