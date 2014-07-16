package XAS::Lib::Services;

our $VERSION = '0.03';

use POE;

my $mixin;
BEGIN {
    $mixin = ($^O eq 'MSWin32')
        ? 'XAS::Lib::Services::Win32'
        : 'XAS::Lib::Services::Unix';
}

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::Session',
  mixin     => $mixin,
  accessors => 'sessions',
  mutators  => 'last_state',
  constants => 'DELIMITER',
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

sub register {
    my $self = shift;

    my ($sessions) = $self->validate_params(\@_, [1]);

    if (ref($sessions) eq 'ARRAYREF') {

        foreach my $session (@$sessions) {

            push(@{$self->{sessions}}, $session);

        }

    } else {

        my @parts = split(DELIMITER, $sessions);

        foreach my $session (@parts) {

            push(@{$self->{sessions}}, $session);

        }

    }

}

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

sub session_shutdown {
    my $self = shift;

    $poe_kernel->delay('poll');
    $self->SUPER::session_shutdown();

}

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _session_init {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: _session_init()");

    $poe_kernel->state('poll', $self, '_poll');

    $self->last_state(SERVICE_START_PENDING);
    $self->_current_state(SERVICE_START_PENDING);

    $self->init_service();
    $self->session_initialize();

    $poe_kernel->post($alias, 'poll');

}

sub _poll {
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

        $self->log->debug("$alias: state = SERVICE_CONTINUE_PENDING");

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
        $poe_kernel->post($alias, 'session_shutdown');
        $self->last_state(SERVICE_STOPPED);

    } elsif ($state == SERVICE_CONTROL_SHUTDOWN) {

        $self->log->debug("$alias: state = SERVICE_CONTROL_SHUTDOWN");

        # shutdown...

        unless ($self->last_state == SERVICE_PAUSED) {

            $self->_service_shutdown();
            $delay = $self->shutdown_interval;
            $self->last_state(SERVICE_STOP_PENDING);

        }

    }

    # tell the SCM what is going on

    $self->_current_state($self->last_state, $delay);

    # queue the next polling interval

    unless ($delay == 0) {

        $stat = $poe_kernel->delay('poll', $self->poll_interval);
        $self->log->error("unable to queue delay - $stat") if ($stat != 0);

    }

    $self->log->debug("$alias: leaving _poll()");

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{sessions} = [];

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

XAS::Lib::Services - A class to interact with Services

=head1 SYNOPSIS

 use POE;
 use XAS::Lib::Service;
 use XAS::Lib::Services;

 my $service = XAS::Lib::Services->new(
    -alias             => 'service',
    -poll_interval     => 2,
    -shutdown_interval => 25
 );

 my $task = XAS::Lib::Service->new(
     -alias => 'task'
 );

 $service->register('task');
 $poe_kernel->run();

=head1 DESCRIPTION

This module provides a generic interface to "Services". A Service is
a managed background process. It responds to external events. On Windows
this would be responding to commands from the Service Control Manager. 
On Unix this would be responding to a special set of signals. This module 
provides an event loop that can interact those external events. 

When an external event happens this module will trap it and generate a POE 
event. This event is then sent to all interested modules. The following POE 
events have been defined:

=over 4

=item B<session_startup> 

This is fired when your process starts up and is used to initialize what ever
processing you are going to do. On a network server, this may be opening a
port to listen on.

=item B<session_shutdown>

This is fired when your process is shutting down. 

=item B<session_pause>

This is fired when your process needs to "pause".

=item B<session_resume>

This is fired when your process needs to "resume".

=item B<session_idle>

This is fired at every poll_interval.

=back

These events follow closely the model defined by the Windows Service 
Control Manager interface. To use these events it is best to inherit from
L<XAS::Lib::Service>. 

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

=head2 register($session)

This allows your process to register whatever modules you want events sent too.

=over 4

=item B<$session>

This can be an array reference or a text string. The text string may be 
delimited with commas.

=back


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
