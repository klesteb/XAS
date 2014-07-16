package XAS::Lib::Net::POE::Client;

our $VERSION = '0.01';

use POE;
use Try::Tiny;
use Socket ':all';
use POE::Filter::Line;
use POE::Wheel::ReadWrite;
use POE::Wheel::SocketFactory;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::Service',
  mixin     => 'XAS::Lib::Mixins::Keepalive',
  accessors => 'wheel host port listener',
  vars => {
    PARAMS => {
      -host            => 1,
      -port            => 1,
      -retry_reconnect => { optional => 1, default => 1 },
      -tcp_keepalive   => { optional => 1, default => 0 },
      -filter          => { optional => 1, default => undef },
      -alias           => { optional => 1, default => 'client' },
      -eol             => { optional => 1, default => "\012\015" },
    }
  }
;

our @ERRORS = qw(0 32 68 73 78 79 110 104 111);
our @RECONNECTIONS = qw(60 120 240 480 960 1920 3840);

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

# ---------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------

sub session_intialize {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_initialize()");

    # private events

    $self->log->debug("$alias: doing private events");

    # private events

    $poe_kernel->state('server_connected', $self, '_server_connected');
    $poe_kernel->state('server_connect',   $self, '_server_connect');
    $poe_kernel->state('server_error',     $self, '_server_error');
    $poe_kernel->state('server_message',   $self, '_server_message');

    # public events

    $self->log->debug("$alias: doing public events");

    $poe_kernel->state('read_data',         $self);
    $poe_kernel->state('write_data',        $self);
    $poe_kernel->state('connection_up',     $self);
    $poe_kernel->state('connection_down',   $self);
    $poe_kernel->state('handle_connection', $self);

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leaving session_initialize()");

}

sub session_startup {
    my ($self) = @_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: session_startup");

    $poe_kernel->post($alias, 'server_connect');

}

sub session_shutdown {
    my $self = shift;
    
    $self->{wheel}    = undef;
    $self->{listener} = undef;

    # walk the chain

    $self->SUPER::session_shutdown();

}

sub session_pause {
    my ($self) = @_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: session_pause");

    $poe_kernel->call($alias, 'connection_down');

}

sub session_resume {
    my ($self) = @_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: session_resume");

    $poe_kernel->call($alias, 'connection_up');

}

# ---------------------------------------------------------------------
# Public Events
# ---------------------------------------------------------------------

sub handle_connection {
    my ($self) = @_[OBJECT];

}

sub connection_down {
    my ($self) = @_[OBJECT];

}

sub connection_up {
    my ($self) = @_[OBJECT];

}

sub read_data {
    my ($self, $data) = @_[OBJECT,ARG0];

    my $alias = $self->alias;

    $poe_kernel->post($alias, 'write_data', $data);

}

sub write_data {
    my ($self, $data) = @_[OBJECT, ARG0];

    my @packet;

    push(@packet, $data);

    if (my $wheel = $self->wheel) {

        $wheel->put(@packet);

    }

}

# ---------------------------------------------------------------------
# Private Events
# ---------------------------------------------------------------------

sub _server_message {
    my ($self, $data, $wheel_id) = @_[OBJECT, ARG0, ARG1];

    my $alias = $self->alias;

    $self->log->debug("$alias: _server_message()");

    $poe_kernel->post($alias, 'read_data', $data);

}

sub _server_connected {
    my ($self, $socket, $peeraddr, $peerport, $wheel_id) = @_[OBJECT,ARG0..ARG3];

    my $alias = $self->alias;

    $self->log->debug("$alias: _server_connected()");

    if ($self->tcp_keepalive) {

        $self->log->debug("$alias: keepalive activated");

        $self->enable_keepalive($socket);

    }

    my $wheel = POE::Wheel::ReadWrite->new(
        Handle     => $socket,
        Filter     => $self->filter,
        InputEvent => 'server_message',
        ErrorEvent => 'server_error',
    );

    my $host = gethostbyaddr($peeraddr, AF_INET);

    $self->{attempts} = 0;
    $self->{wheel} = $wheel;
    $self->{host} = $host;
    $self->{port} = $peerport;

    $poe_kernel->post($alias, 'handle_connection');

}

sub _server_connect {
    my ($self) = @_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: _server_connect()");

    $self->{listner} = POE::Wheel::SocketFactory->new(
        RemoteAddress  => $self->host,
        RemotePort     => $self->port,
        SocketType     => SOCK_STREAM,
        SocketDomain   => AF_INET,
        Reuse          => 'no',
        SocketProtocol => 'tcp',
        SuccessEvent   => 'server_connected',
        FailureEvent   => 'server_connection_failed',
    );

}

sub _server_connection_failed {
    my ($self, $operation, $errnum, $errstr, $wheel_id) = @_[OBJECT,ARG0..ARG3];

    my $alias = $self->alias;

    $self->log->debug("$alias: _server_connection_failed()");
    $self->log->error("$alias: operation: $operation; reason: $errnum - $errstr");

    delete $self->{listner};
    delete $self->{wheel};

    foreach my $error (@ERRORS) {

        $self->_reconnect($kernel) if ($errnum == $error);

    }

}

sub _server_error {
    my ($self, $operation, $errnum, $errstr, $wheel_id) = @_[OBJECT,ARG0..ARG3];

    my $alias = $self->alias;

    $self->log->debug("$alias: _server_error()");
    $self->log->error("$alias: operation: $operation; reason: $errnum - $errstr");

    delete $self->{listner};
    delete $self->{wheel};

    $poe_kernel->post($alias, 'connection_down');

    foreach my $error (@ERRORS) {

        $self->_reconnect($kernel) if ($errnum == $error);

    }

}

# ---------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{attempts} = 0;
    $self->{count} = scalar(@RECONNECTIONS);

    $self->init_keepalive();     # init tcp keepalive definations

    unless (defined($self->{filter})) {

        $self->{filter} = POE::Filter::Line->new(
            InputLiteral  => $self->eol,
            OutputLiteral => $self->eol,
        );

    }

    return $self;

}

sub _reconnect {
    my ($self) = shift;

    my $retry;
    my $alias = $self->alias;

    $self->log->debug("$alias: attempts: $self->{attempts}, count: $self->{count}");

    if ($self->{attempts} < $self->{count}) {

        my $delay = $RECONNECTIONS[$self->{attempts}];
        $self->log->warn("$alias: attempting reconnection: $self->{attempts}, waiting: $delay seconds");
        $self->{attempts} += 1;
        $poe_kernel->delay('server_connect', $delay);

    } else {

        $retry = $self->retry_reconnect || 0;

        if ($retry) {

            $self->log->warn("$alias: cycling reconnection attempts, but not shutting down...");
            $self->{attempts} = 0;
            $poe_kernel->post($alias, 'server_connect');

        } else {

            $self->log->warn("$alias: shutting down, to many reconnection attempts");
            $poe_kernel->post($alias, 'shutdown');

        }

    }

}

1;

__END__

=head1 NAME

XAS::Lib::Net::POE::Client - An asynchronous network client based on POE

=head1 SYNOPSIS

This module is a class used to create network clients.

 package Client;

 use POE;
 use XAS::Class
   version => '1.0',
   base    => 'XAS::Lib::Net::POE::Client'
 ;

 sub handle_connection {
    my ($self) = @_[OBJECT];

    my $packet = "hello!";

    $poe_kernel->yield('write_data', $packet);

 }

=head1 DESCRIPTION

This module handles the nitty-gritty details of setting up the communications
channel to a server. You will need to sub-class this module with your own for
it to be useful.

An attempt to maintain that channel will be made when/if that server should
happen to disappear off the network. There is nothing more unpleasant then
having to go around to dozens of servers and restarting processes.

=head1 METHODS

=head2 new

This method initializes the class and starts a session to handle the
communications channel. It takes the following parameters:

=over 4

=item B<-alias>

The session alias, defaults to 'client'.

=item B<-server>

The servers host name.

=item B<-port>

The servers port number.

=item B<-retry_count>

Wither to attempt reconnections after they run out. Defaults to true.

=item B<-tcp_keepalive>

For those pesky firewalls, defaults to false

=back

=head2 read_data

This event is triggered when data is received for the server.

=head2 write_data

You use this event to send data to the server.

=head2 handle_connection

This event is triggered upon initial connection to the server.

=head2 connection_down

This event is triggered to allow you to be notified if
the connection to the server is currently down.

=head2 connection_up

This event is triggered to allow you to be notified when the connection
to the server is restored.

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
