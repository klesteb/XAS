package XAS::Lib::Services;

our $VERSION = '0.03';

use POE;

my $mixin;
BEGIN {
    $mixin = ($^O eq 'MSWin32')
        ? 'XAS::Lib::Service::Win32'
        : 'XAS::Lib::Service::Unix';
}

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::Session',
  mixin     => $mixin,
  accessors => 'sessions',
  mutators  => 'last_state',
  constants => 'ARRAYREF DELIMITER',
  messages => {
    noservice => 'unable to start service; reason: %s',
    paused    => 'the service is already paused',
    unpaused  => 'the service is not paused',
  },
  vars => {
    PARAMS => {
      -poll_interval     => { optional => 1, default => 2 },
      -shutdown_interval => { optional => 1, default => 25 },
    }
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub session_initialize {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_initialize()");

    $self->init_service();

    $poe_kernel->state('poll', $self, '_poll');

    $self->last_state(SERVICE_START_PENDING);
    $self->_current_state(SERVICE_START_PENDING);

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leaving session_initialize()");

}

sub register {
    my $self = shift;

    my ($sessions) = $self->validate_params(\@_, [1]);

    if (ref($sessions) eq ARRAYREF) {

        foreach my $session (@$sessions) {

            push(@{$self->{sessions}}, $session);

        }

    } else {

        my @parts = split(DELIMITER, $sessiones);

        foreach my $session (@parts) {

            push(@{$self->{sessions}}, $session);

        }

    }

}

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Overridden Methods - semi public
# ----------------------------------------------------------------------

sub session_cleanup {
    my $self = shift;

    $poe_kernel->delay('poll');

    # walk the chain

    $self->SUPER::session_cleanup();

}

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _session_init {
    my ($self) = @_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: _session_init()");

    $self->session_initialize();

    $poe_kernel->post($alias, 'poll');
    $poe_kernel->post($alias, 'session_startup');

}

sub _poll {
    my ($self) = @_[OBJECT];

    my $stat;
    my $delay = 0;
    my $state = $self->_current_state();

    $self->log->debug('entering _poll()');
    $self->log->debug("state = $state");

    if ($state == SERVICE_START_PENDING) {

        $self->log->debug('state = SERVICE_START_PENDING');

        # Initialization code

        $self->last_state(SERVICE_START_PENDING);
        $self->_current_state(SERVICE_START_PENDING, 6000);

        # Initialization code
        # ...do whatever you need to do to start...

        $self->_service_startup();
        $self->last_state(SERVICE_RUNNING);

    } elsif ($state == SERVICE_STOP_PENDING) {

        $self->log->debug('state = SERVICE_STOP_PENDING');

        # Stopping...

        $self->_service_shutdown();
        $self->last_state(SERVICE_STOPPED);

    } elsif ($state == SERVICE_PAUSE_PENDING) {

        $self->log->debug('state = SERVICE_PAUSE_PENDING');

        # Pausing...

        $self->_service_paused();
        $self->last_state(SERVICE_PAUSED);

    } elsif ($state == SERVICE_CONTINUE_PENDING) {

        $self->log->debug('state = SERVICE_CONTINUE_PENDING');

        # Resuming...

        if ($self->last_state == SERVICE_PAUSED) {

            $self->_service_resumed();
            $self->last_state(SERVICE_RUNNING);

        } else {

            $self->log->info($self->message('unpaused'));

        }

    } elsif ($state == SERVICE_RUNNING) {

        $self->log->debug('state = SERVICE_RUNNING');

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

        $self->log->debug('state = SERVICE_STOPPED');

        # stopped...

        $delay = $self->poll_interval + 1000;
        $poe_kernel->yield('shutdown');
        $self->last_state(SERVICE_STOPPED);

    } elsif ($state == SERVICE_CONTROL_SHUTDOWN) {

        $self->log->debug('state = SERVICE_CONTROL_SHUTDOWN');

        # shutdown...

        unless ($self->last_state == SERVICE_PAUSED) {

            $delay = $self->shutdown_interval;
            $self->last_state(SERVICE_STOP_PENDING);

        }

    }

    # tell the SCM what is going on

    $self->_current_state($self->last_state, $delay);

    # queue the next polling interval

    $stat = $poe_kernel->delay('poll', $self->poll_interval);
    $self->log->error("unable to queue delay - $stat") if ($stat != 0);

    $self->log->debug('leaving _poll()');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{sessions} = ();

    return $self;

}

sub _service_startup {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: _service_startup");

    foreach my $session (@{$self->sessions}) {

        $poe_kernel->post($session, 'session_startup');

    }

}

sub _service_shutdown {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: _service_shutdown");

    foreach my $session (@{$self->sessions}) {

        $poe_kernel->post($session, 'session_shutdown');

    }

}

sub _service_idle {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: _service_idle");

    foreach my $session (@{$self->sessions}) {

        $poe_kernel->post($session, 'session_idle');

    }

}

sub _service_paused {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: _service_paused");

    foreach my $session (@{$self->sessions}) {

        $poe_kernel->post($session, 'session_pause');

    }

}

sub _service_resumed {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: _service_resumed");

    foreach my $session (@{$self->sessions}) {
        
        $poe_kernel->post($session, 'session_resume');
        
    }

}

1;

__END__

=head1 NAME

XAS::Lib::Services - A base class for Services

=head1 SYNOPSIS

 use XAS::Lib::Service;

 my $sevice = XAS::Lib::Services->new(
    -alias             => 'session',
    -poll_interval     => 2,
    -shutdown_interval => 25
 );

=head1 DESCRIPTION

This module provides a generic interface to "Services". A Service is
a managed background process. It reponds to external stimuli. On Windows
this would be responding to commands from the SCM. On Unix this would be
responding to a special set of signals. A service can be stopped, started,
paused and resumed.

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

It also use parameters from L<XAS::Lib::Session>.

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

=head2 service_resumed()

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
