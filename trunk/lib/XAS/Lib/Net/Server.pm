package XAS::Lib::Net::Server;

our $VERSION = '0.01';

use POE;
use Socket ':all';
use POE::Filter::Line;
use POE::Wheel::ReadWrite;
use POE::Wheel::SocketFactory;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::Service',
  mixin     => 'XAS::Lib::Mixins::Keepalive',
  utils     => 'weaken params',
  accessors => 'session',
  constants => 'ARRAY',
  vars => {
    PARAMS => {
      -port             => 1,
      -tcp_keepalive    => { optional => 1, default => 0 },
      -inactivity_timer => { optional => 1, default => 600 },
      -filter           => { optional => 1, default => undef },
      -address          => { optional => 1, default => 'localhost' },
      -eol              => { optional => 1, default => "\012\015" },
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub session_initialize {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_intialize()");

    $poe_kernel->state('process_errors',   $self);
    $poe_kernel->state('process_request',  $self);
    $poe_kernel->state('process_response', $self);

    # private events

    $poe_kernel->state('client_error',             $self, '_client_error');
    $poe_kernel->state('client_input',             $self, '_client_input');
    $poe_kernel->state('client_reaper',            $self, '_client_reaper');
    $poe_kernel->state('client_output',            $self, '_client_output');
    $poe_kernel->state('client_connected',         $self, '_client_connected');
    $poe_kernel->state('client_connection',        $self, '_client_connection');
    $poe_kernel->state('client_connection_failed', $self, '_client_connection_failed');

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leaving session_intialize()");

}

sub session_startup {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_startup()");

    $poe_kernel->call($alias, 'client_connection');

    # walk the chain

    $self->SUPER::session_startup();

    $self->log->debug("$alias: leaving session_startup()");

}

sub session_shutdown {
    my $self = shift;

    my $alias = $self->alias;
    my $clients = $self->{clients};

    $self->log->debug("$alias: entering session_shutdown()");

    while (my $client = keys %$clients) {

        $poe_kernel->alarm_remove($client->{watchdog});
        $client = undef;

    }

    delete $self->{listener};

    # walk the chain

    $self->SUPER::session_shutdown();

    $self->log->debug("$alias: leaving session_shutdown()");

}

sub session_pause {
    my $self = shift;

    my $alias = $self->alias;
    my $clients = $self->{clients};

    $self->log->debug("$alias: entering session_pause()");

    while (my $wheel = keys %$clients) {

        $wheel->pause_input();
        $poe_kernel->alarm_remove($wheel->{watchdog});

    }

    # walk the chain

    $self->SUPER::session_pause();

    $self->log->debug("$alias: entering session_pause()");

}

sub session_resume {
    my $self = shift;

    my $alias = $self->alias;
    my $clients = $self->{clients};
    my $inactivity = $self->inactivity_timer;

    $self->log->debug("$alias: entering session_resume()");

    while (my $wheel = keys %$clients) {

        $wheel->resume_input();
        $poe_kernel->alarm_set('client_reaper', $inactivity, $wheel);

    }

    # walk the chain

    $self->SUPER::session_resume();

    $self->log->debug("$alias: leaving session_resume()");

}

sub reaper {
    my ($self, $wheel) = @_;

    my $alias = $self->alias;

    $self->log->debug_msg('reaper', $alias, $self->host($wheel), $self->peerport($wheel));

}

# ----------------------------------------------------------------------
# Public Accessors
# ----------------------------------------------------------------------

sub peerport {
    my ($self, $wheel) = @_;

    return $self->{clients}->{$wheel}->{port};

}

sub peerhost {
    my ($self, $wheel) = @_;

    return $self->{clients}->{$wheel}->{host};

}

sub client {
    my ($self, $wheel) = @_;

    return $self->{clients}->{$wheel}->{client};

}

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

sub process_request {
    my ($self, $input, $ctx) = @_[OBJECT,ARG0,ARG1];

    my $output = $input;
    my $alias = $self->alias;

    $poe_kernel->post($alias, 'process_response', $output, $ctx);

}

sub process_response {
    my ($self, $output, $ctx) = @_[OBJECT,ARG0,ARG1];

    my $alias = $self->alias;

    $poe_kernel->post($alias, 'client_output', $output, $ctx);

}

sub process_errors {
    my ($self, $output, $ctx) = @_[OBJECT,ARG0,ARG1];

    my $alias = $self->alias;

    $poe_kernel->post($alias, 'client_output', $output, $ctx);

}

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _client_connection {
    my ($self) = @_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: _client_connection()");

    # start listening for connections

    $self->{listener} = POE::Wheel::SocketFactory->new(
        BindAddress    => $self->address,
        BindPort       => $self->port,
        SocketType     => SOCK_STREAM,
        SocketDomain   => AF_INET,
        SocketProtocol => 'tcp',
        Reuse          => 1,
        SuccessEvent   => 'client_connected',
        FailureEvent   => 'client_connection_failed'
    );

}

sub _client_connected {
    my ($self, $socket, $peeraddr, $peerport, $wheel_id) = @_[OBJECT,ARG0..ARG3];

    my $alias = $self->alias;
    my $inactivity = $self->inactivity_timer;

    $self->log->debug("$alias: _client_connected()");

    if ($self->tcp_keepalive) {

        $self->log->debug("$alias: keepalive activated");

        $self->enable_keepalive($socket);

    }

    my $client = POE::Wheel::ReadWrite->new(
        Handle     => $socket,
        Filter     => $self->filter,
        InputEvent => 'client_input',
        ErrorEvent => 'client_error'
    );

    my $wheel = $client->ID;
    my $host = gethostbyaddr($peeraddr, AF_INET);

    $self->{clients}->{$wheel}->{host}   = $host;
    $self->{clients}->{$wheel}->{port}   = $peerport;
    $self->{clients}->{$wheel}->{client} = $client;
    $self->{clients}->{$wheel}->{active} = time();
    $self->{clients}->{$wheel}->{watchdog} = $poe_kernel->alarm_set('client_reaper', $inactivity, $wheel);

    $self->log->info_msg('client_connect', $alias, $host, $peerport);

}

sub _client_connection_failed {
    my ($self, $syscall, $errnum, $errstr, $wheel) = @_[OBJECT,ARG0..ARG3];

    my $alias = $self->alias;

    $self->log->error_msg('connection_failed', $alias, $errnum, $errstr);

    delete $self->{listener};

}

sub _client_input {
    my ($self, $input, $wheel) = @_[OBJECT,ARG0,ARG1];

    my $alias = $self->alias;
    my $ctx = {
        wheel => $wheel
    };

    $self->log->debug("$alias: _client_input()");

    $self->{clients}->{$wheel}->{active} = time();

    $poe_kernel->post($alias, 'process_request', $input, $ctx);

}

sub _client_output {
    my ($self, $data, $ctx) = @_[OBJECT,ARG0,ARG1];

    my @packet;
    my $alias = $self->alias;

    push(@packet, $data);

    $self->log->debug("$alias: _client_output()");

    if (my $wheel = $ctx->{wheel})) {

        $self->{clients}->{$wheel}->{client}->put(@packet);

    } else {

        $self->log->error_msg('nowheel', $alias);

    }

}

sub _client_error {
    my ($self, $syscall, $errnum, $errstr, $wheel) = @_[OBJECT,ARG0..ARG3];

    my $alias = $self->alias;

    $self->log->debug("$alias: _client_error()");

    if ($errnum == 0) {

        $self->log->info_msg('client_disconnect', $alias, $self->peerhost($wheel), $self->peerport($wheel));

    } else {

        $self->log->error_msg('client_error', $alias, $errnum, $errstr);

    }

    delete $self->{clients}->{$wheel};

}

sub _client_reaper {
    my ($self, $wheel) = @_[OBJECT,ARG0];

    my $timeout = time() - $self->inactivity_timer;

    if ($self->{clients}->{$wheel}->{active} < $timeout) {

        $self->reaper($wheel);

    }

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->init_keepalive();     # init tcp keepalive definations

    unless (defined($self->filter)) {

        $self->{filter} = POE::Filter::Line->new(
            InputLiteral  => $self->eol,
            OutputLiteral => $self->eol,
        );

    }

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Net::Server - A basic network server for the XAS Environment

=head1 SYNOPSIS

 my $server = XAS::Lib::Net::Server->new(
     -port             => 9505,
     -address          => 'localhost',
     -filter           => POE::Filter::Line->new(),
     -alias            => 'server',
     -inactivity_timer => 600,
     -eol              => "\012\015"
 }

=head1 DESCRIPTION

This module implements a simple text orientated network protocol. Data is
sent out as "packets". Which means everything is delimited with a consistent
EOL. These packets may be formatted strings, such as JSON. This module inherits
from L<XAS::Lib::Session>.

=head1 METHODS

=head2 new

This initializes the module and starts listening for requests. There are
five parameters that can be passed. They are the following:

=over 4

=item B<-alias>

The name of the POE session.

=item B<-port>

The IP port to listen on.

=item B<-address>

The address to bind too.

=item B<-inactivity_timer>

Sets an inactivity timer on clients. When it is surpassed, the method reaper()
is called with the POE wheel id. What reaper() does is application specific.
The default is 600 seconds.

=item B<-filter>

An optional filter to use, defaults to POE::Filter::Line

=item B<-eol>

An optional EOL, defaults to "\012\015";

=back

=head2 reaper($wheel)

Called when the inactivity timer is triggered.

=over 4

=item B<$wheel>

The POE wheel that triggered the timer.

=back

=head1 ACCESSORS

=head2 peerport($wheel)

This returns the current port for that wheel.

=over 4

=item B<$wheel>

The POE wheel to use.

=back

=head2 host($wheel)

This returns the current host name for that wheel.

=over 4

=item B<$wheel>

The POE wheel to use.

=back

=head2 client($wheel)

This returns the current client for that wheel.

=over 4

=item B<$wheel>

The POE wheel to use.

=back

=head1 PUBLIC EVENTS

=head2 process_request(OBJECT, ARG0, ARG1)

This event will process the input from the client. It takes the
following parameters:

=over 4

=item B<OBJECT>

A handle to the current object.

=item B<ARG0>

The input received from the socket.

=item B<ARG1>

A hash variable to maintain context. This will be initialized with a "wheel"
field. Others fields may be added as needed.

=back

=head2 process_response(OBJECT, ARG0, ARG1)

This event will process the output from the client. It takes the
following parameters:

=over 4

=item B<OBJECT>

A handle to the current object.

=item B<ARG0>

The output to be sent to the socket.

=item B<ARG1>

A hash variable to maintain context. This uses the "wheel" field to direct output
to the correct socket. Others fields may have been added as needed.

=back

=head2 process_errors(OBJECT, ARG0, ARG1)

This event will process the error output from the client. It takes the
following parameters:

=over 4

=item B<OBJECT>

A handle to the current object.

=item B<ARG0>

The output to be sent to the socket.

=item B<ARG1>

A hash variable to maintain context. This uses the "wheel" field to direct output
to the correct socket. Others fields may have been added as needed.

=back

=head1 SEE ALSO

=over 4

=item POE::Filter::Line

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
