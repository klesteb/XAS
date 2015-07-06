package XAS::Lib::Net::Server;

our $VERSION = '0.04';

use POE;
use Try::Tiny;
use Socket ':all';
use POE::Filter::Line;
use POE::Wheel::ReadWrite;
use POE::Wheel::SocketFactory;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::POE::Service',
  mixin     => 'XAS::Lib::Mixins::Handlers',
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
      -eol              => { optional => 1, default => "\015\012" },
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

    # private events

    $poe_kernel->state('client_error',             $self, '_client_error');
    $poe_kernel->state('client_input',             $self, '_client_input');
    $poe_kernel->state('client_reaper',            $self, '_client_reaper');
    $poe_kernel->state('client_output',            $self, '_client_output');
    $poe_kernel->state('client_connected',         $self, '_client_connected');
    $poe_kernel->state('client_connection',        $self, '_client_connection');
    $poe_kernel->state('client_connection_failed', $self, '_client_connection_failed');

    $poe_kernel->state('process_errors',    $self, '_process_errors');
    $poe_kernel->state('process_request',   $self, '_process_request');
    $poe_kernel->state('process_response',  $self, '_process_response');
    $poe_kernel->state('handle_connection', $self, '_handle_connection');

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

    $self->log->debug("$alias: leaving session_pause()");

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
    my $self = shift;
    my ($wheel) = $self->validate_params(\@_, [1]);

    my $alias = $self->alias;

    $self->log->debug_msg('net_client_reaper', $alias, $self->host($wheel), $self->peerport($wheel));

}

sub process_request {
    my $self = shift;
    my ($input, $ctx) = $self->validate_params(\@_, [1,1]);

    return $input;

}

sub process_response {
    my $self = shift;
    my ($output, $ctx) = $self->validate_params(\@_, [1,1]);

    return $output;

}

sub process_errors {
    my $self = shift;
    my ($output, $ctx) = $self->validate_params(\@_, [1,1]);

    return $output;

}

sub handle_connection {
    my $self = shift;
    my ($wheel) = $self->validate_params(\@_, [1]);
    
}

# ----------------------------------------------------------------------
# Public Accessors
# ----------------------------------------------------------------------

sub peerport {
    my $self = shift;
    my ($wheel) = $self->validate_params(\@_, [1]);

    return $self->{clients}->{$wheel}->{port};

}

sub peerhost {
    my $self = shift;
    my ($wheel) = $self->validate_params(\@_, [1]);

    return $self->{clients}->{$wheel}->{host};

}

sub client {
    my $self = shift;
    my ($wheel) = $self->validate_params(\@_, [1]);

    return $self->{clients}->{$wheel}->{client};

}

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _process_request {
    my ($self, $input, $ctx) = @_[OBJECT,ARG0,ARG1];

    my $alias = $self->alias;
    my $data  = $self->process_request($input, $ctx);

    $self->log->debug("$alias: _process_request()");
    $poe_kernel->post($alias, 'process_response', $data, $ctx);

}

sub _process_response {
    my ($self, $output, $ctx) = @_[OBJECT,ARG0,ARG1];

    my $alias = $self->alias;
    my $data  = $self->process_response($output, $ctx);

    $self->log->debug("$alias: _process_response()");
    $poe_kernel->post($alias, 'client_output', $data, $ctx);

}

sub _process_errors {
    my ($self, $output, $ctx) = @_[OBJECT,ARG0,ARG1];

    my $alias = $self->alias;
    my $data  = $self->process_errors($output, $ctx);

    $self->log->debug("$alias: _process_errors()");
    $poe_kernel->post($alias, 'client_output', $data, $ctx);

}

sub _handle_connection {
    my ($self, $wheel) = @_[OBJECT, ARG0];

    my $alias = $self->alias;

    $self->log->debug("$alias: _handle_connection()");
    $self->handle_connection($wheel);

}

sub _client_connection {
    my ($self) = $_[OBJECT];

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
    $self->{clients}->{$wheel}->{socket} = $socket;
    $self->{clients}->{$wheel}->{watchdog} = $poe_kernel->alarm_set('client_reaper', $inactivity, $wheel);

    $self->log->info_msg('net_client_connect', $alias, $host, $peerport);

    $poe_kernel->post($alias, 'handle_connection', $wheel);
    
}

sub _client_connection_failed {
    my ($self, $syscall, $errnum, $errstr, $wheel) = @_[OBJECT,ARG0..ARG3];

    my $alias = $self->alias;

    $self->log->error_msg('net_client_connection_failed', $alias, $errnum, $errstr);

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

    my $alias = $self->alias;
    my $wheel = $ctx->{wheel};
    my @buffer;

    $self->log->debug("$alias: _client_output()");

    try {

        if (defined($wheel)) {

            # emulate IO::Socket connected() method. this method
            # calls getpeername(). getpeername() returns undef when
            # the network stack can't validate the socket. 

            if (getpeername($self->{clients}->{$wheel}->{socket})) {

                push(@buffer, $data);
                $self->{clients}->{$wheel}->{client}->put(@buffer);

            } else {

                $self->log->error_msg(
                    'net_client_nosocket', 
                    $alias, 
                    $self->peerhist($wheel), 
                    $self->peerport($wheel)
                );
                delete $self->{clients}->{$wheel};

            }

        } else {

            $self->log->error_msg('net_client_nowheel', $alias);

        }

    } catch {

        my $ex = $_;

        $self->exception_handler($ex);

        delete $self->{clients}->{$wheel};

    };

}

sub _client_error {
    my ($self, $syscall, $errnum, $errstr, $wheel) = @_[OBJECT,ARG0..ARG3];

    my $alias = $self->alias;

    $self->log->debug("$alias: _client_error()");

    if ($errnum == 0) {

        $self->log->info_msg('net_client_disconnect', $alias, $self->peerhost($wheel), $self->peerport($wheel));

    } else {

        $self->log->error_msg('net_client_error', $alias, $errnum, $errstr);

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
     -host             => 'localhost',
     -filter           => POE::Filter::Line->new(),
     -alias            => 'server',
     -inactivity_timer => 600,
     -eol              => "\015\012"
 }

=head1 DESCRIPTION

This module implements a simple text orientated network protocol. Data is
sent out as delimited strings. Which means every string has a consistent EOL. 
These strings may be formatted, such as JSON. This module inherits from 
L<XAS::Lib::POE::Session|XAS::Lib::POE::Session>.

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

An optional EOL, defaults to "\015\012";

=back

=head2 reaper($wheel)

Called when the inactivity timer is triggered.

=over 4

=item B<$wheel>

The POE wheel that triggered the timer.

=back

=head2 process_request($input, $ctx)

This method will process the input from the client. It takes the
following parameters:

=over 4

=item B<$input>

The input received from the socket.

=item B<$ctx>

A hash variable to maintain context. This will be initialized with a "wheel"
field. Others fields may be added as needed.

=back

=head2 process_response($output, $ctx)

This method will process the output from the client. It takes the
following parameters:

=over 4

=item B<$output>

The output to be sent to the socket.

=item B<$ctx>

A hash variable to maintain context. This uses the "wheel" field to direct 
output to the correct socket. Others fields may have been added as needed.

=back

=head2 process_errors($output, $ctx)

This method will process the error output from the client. It takes the
following parameters:

=over 4

=item B<$output>

The output to be sent to the socket.

=item B<$ctx>

A hash variable to maintain context. This uses the "wheel" field to direct 
output to the correct socket. Others fields may have been added as needed.

=back

=head2 handle_connection($wheel)

This method is called after the client connects. This is for additional
post connection processing as needed. It takes the following parameters:

=over 4

=item B<$wheel>

The id of the clients wheel.

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

=head1 SEE ALSO

=over 4

=item L<POE::Filter::Line|https://metacpan.org/pod/POE::Filter::Line>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
