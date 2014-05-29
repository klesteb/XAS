package XAS::Lib::Net::Client::Stomp;

our $VERSION = '0.02';

use POE;
use Try::Tiny;
use POE::Filter::Stomp;
use POE::Component::Client::Stomp::Utils;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::Net::Client::POE',
  mixin     => 'XAS::Lib::Mixins::Handlers',
  codec     => 'JSON',
  constants => 'ARRAY',
  accessors => 'stomp',
  vars => {
    PARAMS => {
      -login    => { optional => 1, default => 'guest' },
      -passcode => { optional => 1, default => 'guest' },
      -filter   => { optional => 1, default => POE::Filter::Stomp->new() },
    }
  },
  messages => {
    'initialize'   => '%s: unable to initialize: %s; reason %s',
    'connected'    => '%s: connected to %s on %s',
    'subscribed'   => '%s: subscribed to %s',
    'receipts'     => '%s: received a receipt %s',
    'unsubscribed' => '%s: unsubscribed from %s',
    'errors'       => '%s: received an error %s, message: %s, reason: %s',
    'unknowntype'  => '%s: unknown packet type: %s',
    'unknown'      => '%s: %s',
    'received'     => '%s: recieved message %s, type: "%s" from %s',
  }
;

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

sub handle_connected {
    my ($kernel, $self, $frame) = @_[KERNEL, OBJECT, ARG0];

    my $alias = $self->alias;
    my $queue = $self->queue;

    $kernel->yield('connection_up');

}

sub handle_connection {
    my ($kernel, $self) = @_[KERNEL, OBJECT];

    my $alias  = $self->alias;

    my $frame = $self->stomp->connect({
        login    => $self->login,
        passcode => $self->passcode,
    });

    $self->log->info_msg('connected', $alias, $self->host, $self->port);
    $kernel->yield('write_data', $frame);

}

sub handle_receipt {
    my ($kernel, $self, $frame) = @_[KERNEL, OBJECT, ARG0];

    my $alias  = $self->alias;

    $self->log->info_msg('receipts', $alias, $frame->headers->{'message-id'});

}

sub handle_error {
    my ($kernel, $self, $frame) = @_[KERNEL, OBJECT, ARG0];

    my $alias  = $self->alias;

    $self->log->error_msg(
        'errors',
        $alias,
        $frame->headers->{'message-id'} || '',
        $frame->headers->{'message'} || '',
        $frame->body
    );

}

sub handle_message {
    my ($kernel, $self, $frame) = @_[KERNEL,OBJECT,ARG0];

    my $alias = $self->alias;

    $self->log->debug("$alias: handle_message()");

}

sub handle_noop {
    my ($kernel, $self, $frame) = @_[KERNEL,OBJECT,ARG0];

    my $alias = $self->alias;

    $self->log->debug("$alias: handle_noop()");

}

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Overridden Methods - semi public
# ----------------------------------------------------------------------

sub session_intialize {
    my ($self, $kernel, $session) = @_;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_initialize()");

    # private events

    $self->log->debug("$alias: doing private events");

    # private events

    $kernel->state('handle_noop',       $self);
    $kernel->state('handle_error',      $self);
    $kernel->state('handle_message',    $self);
    $kernel->state('handle_receipt',    $self);
    $kernel->state('handle_connected',  $self);

    # public events

    $self->log->debug("$alias: doing public events");

    # walk the chain

    $self->SUPER::session_initialize($kernel, $session);

    $self->log->debug("$alias: leaving session_initialize()");

}

sub session_cleanup {
    my ($self, $kernel, $session) = @_;

    my $params = {};
    my $frame = $self->stomp->disconnect($params);

    $kernel->call($session, 'write_data', $frame);

    # walk the chain

    $self->SUPER::session_cleanup($kernel, $session);

}

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _server_message {
    my ($kernel, $self, $frame, $wheel_id) = @_[KERNEL, OBJECT, ARG0, ARG1];

    my $alias = $self->alias;

    $self->log->debug("$alias: _server_message()");

    if ($frame->command eq 'CONNECTED') {

        $self->log->debug("$alias: received a \"CONNECTED\" message");
        $kernel->yield('handle_connected', $frame);

    } elsif ($frame->command eq 'MESSAGE') {

        $self->log->debug("$alias: received a \"MESSAGE\" message");
        $kernel->yield('handle_message', $frame);

    } elsif ($frame->command eq 'RECEIPT') {

        $self->log->debug("$alias: received a \"RECEIPT\" message");
        $kernel->yield('handle_receipt', $frame);

    } elsif ($frame->command eq 'ERROR') {

        $self->log->debug("$alias: received an \"ERROR\" message");
        $kernel->yield('handle_error', $frame);

    } elsif ($frame->command eq 'NOOP') {

        $self->log->debug("$alias: received an \"NOOP\" message");
        $kernel->yield('handle_noop', $frame);

    } else {

        $self->log->warn("$alias: unknown message type: $frame->command");

    }

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{stomp} = POE::Component::Client::Stomp::Utils->new();

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Net::Client::Stomp - A class for interacting with a STOMP message queue

=head1 SYNOPSIS

 use XAS::Lib::Net::Client::Stomp;

=head1 DESCRIPTION

This module will monitor a queue on a STOMP based message queue server.
It will attempt to maintain a connection to the server. It can only
interact with protocol v1.0 servers.

=head1 METHODS

=head2 new

This method intialized the module. It takes the following parameters:

=over 4

=item B<-login>

The login name to use when authenticating. Defaults to 'wise'.

=item B<-passcode>

The passcode to use when authenticating. Defaults to 'wise'.

=item B<-filter>

The filter to use. Defaults to POE::Filter::Stomp. This is to allow for
the nesting of filters, especially if a SSL connection is desired.

=back

This module inherits from L<XAS::Lib::Net::Client::POE> and accepts those
additional parameters.

=head2 cleanup

Disconnects from the STOMP server.

=head2 connection_up

The method performs actions for when the connection to the STOMP server
is active. By default it does nothing.

=head2 connection_down

The method performs actions for when the connection to the STOMP server
is inactive. By default it does nothing.

=head2 handle_message

This method provides a way to respond to 'MESSAGE' frame from the STOMP server,
by default it does nothing.

=head2 handle_error

This method provides a way to respond to 'ERROR' frames from the STOMP server, by
default it writes them to the log file.

=head2 handle_receipt

This method provides a way to respond to 'RECEIPT" frames from the STOMP server,
by default it write the message to the log file.

=head2 handle_connected

This method procide a way to repond to 'CONNECTED' frames, by default it
defers to connection_up().

=head2 handle_connection

This method is ran when an initial connection to the STOMP server is made.
It provides the login and passcode to the server for authentication.

=head1 SEE ALSO

=head2 L<XAS|XAS>

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
