package XAS::Lib::Stomp::POE::Client;

our $VERSION = '0.03';

use POE;
use Try::Tiny;
use XAS::Lib::Stomp::Utils;
use XAS::Lib::Stomp::POE::Filter;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::Net::Client::POE',
  accessors => 'stomp',
  vars => {
    PARAMS => {
      -alias    => { optional => 1, default => 'stomp-client' },
      -host     => { optional => 1, default => 'localhost' },
      -port     => { optional => 1, default => 61613 },
      -login    => { optional => 1, default => 'guest' },
      -passcode => { optional => 1, default => 'guest' },
      -target   => { optional => 1, default => '1.0', regex => qr/(1\.0|1\.1|1\.2)/ },
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

# ---------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------

sub session_initalize {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: session_initialize()");

    # public events

    $self->log->debug("$alias: doing public events");

    $poe_kernel->state('handle_noop',       $self);
    $poe_kernel->state('handle_error',      $self);
    $poe_kernel->state('handle_message',    $self);
    $poe_kernel->state('handle_receipt',    $self);
    $poe_kernel->state('handle_connected',  $self);

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leaving session_initialize()");

}

sub session_shutdown {
    my $self = shift;

    my $alias = $self->alias;
    my $frame = $self->stomp->disconnect(
        -receipt => 'disconnecting'
    );

    $poe_kernel->call($alias, 'write_data', $frame);
    $self->SUPER::session_shutdown();

}

# ---------------------------------------------------------------------
# Public Events
# ---------------------------------------------------------------------

sub handle_connection {
    my ($self) = @_[OBJECT];

    my $alias = $self->alias;
    my $frame = $self->frame->connect(
        -login    => $self->login,
        -passcode => $self->passcode
    );

    $self->log->info_msg('connected', $alias, $self->host, $self->port);
    $poe_kernel->post($alias, 'write_data', $frame);
    
}

sub handle_connected {
    my ($self, $frame) = @_[OBJECT, ARG0];

    my $alias = $self->alias;

    $poe_kernel->post($alias, 'connection_up');

}

sub handle_message {
    my ($self, $frame) = @_[OBJECT, ARG0];

}

sub handle_receipt {
    my ($self, $frame) = @_[OBJECT, ARG0];

}

sub handle_error {
    my ($self, $frame) = @_[OBJECT, ARG0];

    my $alias = $self->alias;

    $self->log->error_msg('errors',
        $alias,
        $frame->header->message_id,
        $frame->header->message,
        $frame->body
    );

}

sub handle_noop {
    my ($self, $frame) = @_[OBJECT, ARG0];

}

# ---------------------------------------------------------------------
# Private Events
# ---------------------------------------------------------------------

sub _server_message {
    my ($self, $frame, $wheel_id) = @_[OBJECT, ARG0, ARG1];

    my $alias = $self->alias;

    $self->log->debug("$alias: _server_message()");

    if ($frame->command eq 'CONNECTED') {

        $self->log->debug("$alias: received a \"CONNECTED\" message");
        $poe_kernel->post($alias, 'handle_connected', $frame);

    } elsif ($frame->command eq 'MESSAGE') {

        $self->log->debug("$alias: received a \"MESSAGE\" message");
        $poe_kernel->post($alias, 'handle_message', $frame);

    } elsif ($frame->command eq 'RECEIPT') {

        $self->log->debug("$alias: received a \"RECEIPT\" message");
        $poe_kernel->post($alias, 'handle_receipt', $frame);

    } elsif ($frame->command eq 'ERROR') {

        $self->log->debug("$alias: received an \"ERROR\" message");
        $poe_kernel->post($alias, 'handle_error', $frame);

    } elsif ($frame->command eq 'NOOP') {

        $self->log->debug("$alias: received an \"NOOP\" message");
        $poe_kernel->post($alias, 'handle_noop', $frame);

    } else {

        $self->log->warn("$alias: unknown message type: $frame->command");

    }

}

# ---------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{stomp} = XAS::Lib::Stomp::Utils->new();

    unless defined($self->{filter}) {

        $self->{filter} = XAS::Lib::Stomp::POE::Filter->new(
            -target => $self->target
        );

    }

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Stomp::POE::Client - A STOMP client for the POE Environment

=head1 SYNOPSIS

This module is a class used to create clients that need to access a 
message server that communicates with the STOMP protocol. Your program could 
look as follows:

 package Client;

 use POE;
 use XAS::Class
   version => '1.0',
   base    => 'XAS::Lib::Stomp::POE::Client',
 ;

 sub handle_connection {
    my ($self) = @_[OBJECT];
 
    my $nframe = $self->stomp->connect(
        -login    => 'testing',
        -passcode => 'testing'
    ); 

    $poe_kernel->yield('send_data', $nframe);

 }

 sub handle_connected {
    my ($self, $frame) = @_[OBJECT, ARG0];

    my $nframe = $self->stomp->subscribe(
        -queue => $self->queue,
        -ack   => 'client'
    );

    $poe_kernel->yield('send_data', $nframe);

 }
 
 sub handle_message {
    my ($self, $frame) = @_[OBJECT, ARG0];

    my $nframe = $self->stomp->ack(
       -message_id => $frame->header->message_id
    );

    $poe_kernel->yield('send_data', $nframe);

 }

 package main;

 use POE;
 use strict;

 Client->new(
    -alias => 'testing',
    -queue => '/queue/testing',
 );

 $poe_kernel->run();

 exit 0;


=head1 DESCRIPTION

This module handles the nitty-gritty details of setting up the communications 
channel to a message queue server. You will need to sub-class this module
with your own for it to be useful.

An attempt to maintain that channel will be made when/if that server should 
happen to disappear off the network. There is nothing more unpleasant then 
having to go around to dozens of servers and restarting processes.

When messages are received, specific events are generated. Those events are 
based on the message type. If you are interested in those events you should 
override the default behavior for those events. The default behavior is to 
do nothing.

=head1 METHODS

=head2 new

This method initializes the class and starts a session to handle the 
communications channel. It takes the following parameters:

=over 4

=item B<-alias>

The session alias, defaults to 'stomp-client'.

=item B<-server>

The servers host name, defaults to 'localhost'.

=item B<-port>

The servers port number, defaults to '61613'.

=item B<-target>

The STOMP protocol version that is targeted. Defaults to '1.0'.

=item B<-retry_count>

Wither to attempt reconnections after they run out. Defaults to true.

=item B<-enable_keepalive>

For those pesky firewalls, defaults to false

=back

=head2 send_data

You use this event to send Stomp frames to the server. 

=over 4

=item Example

 $kernel->yield('send_data', $frame);

=back

=head2 handle_connection

This event is signaled and the corresponding method is called upon initial 
connection to the message server. For the most part you should send a 
"CONNECT" frame to the server.

 Example

    sub handle_connection {
        my ($self) = @_[$OBJECT];
 
       my $nframe = $self->stomp->connect(
           -login => 'testing',
           -passcode => 'testing'
       );

       $poe_kernel->yield('send_data', $nframe);

    }

=head2 handled_connected

This event and corresponding method is called when a "CONNECT" frame is 
received from the server. This means the server will allow you to start
generating/processing frames.

 Example

    sub handle_connected {
        my ($self, $frame) = @_[OBJECT,ARG0];

        my $nframe = $self->stomp->subscribe(
            -queue => $self->queue,
            -ack => 'client'
        );

        $poe_kernel->yield('send_data', $nframe);

    }

This example shows you how to subscribe to a particular queue. The queue name
was passed as a parameter to new().

=head2 handle_message

This event and corresponding method is used to process "MESSAGE" frames. 

 Example

    sub handle_message {
        my ($self, $frame) = @_[OBJECT,ARG0];
 
        my $nframe = $self->stomp->ack(
            -message_id => $frame->header->message_id
        );

        $poe_kernel->yield('send_data', $nframe);

    }

This example really doesn't do much other then "ack" the messages that are
received. 

=head2 handle_receipt

This event and corresponding method is used to process "RECEIPT" frames. 

 Example

    sub handle_receipt {
        my ($self, $frame) = @_[OBJECT,ARG0];

        my $receipt = $frame->header->receipt;

    }

This example really doesn't do much, and you really don't need to worry about
receipts unless you ask for one when you send a frame to the server. So this 
method could be safely left with the default.

=head2 handle_error

This event and corresponding method is used to process "ERROR" frames. 

 Example

    sub handle_error {
        my ($self, $frame) = @_[OBJECT,ARG0];
 
    }

This example really doesn't do much. Error handling is pretty much what the
process needs to do when something unexpected happens.

=head2 handle_noop

This event and corresponding method is used to process "NOOP" frames. 

 Example

    sub handle_noop {
        my ($self, $frame) = @_[OBJECT,ARG0];
 
    }

This example really doesn't do much. 

=head2 gather_data

This event and corresponding method is used to "gather data". How that is done
is up to your program. But usually a "send_data" event is generated.

 Example

    sub gather_data {
        my ($self) = @_[OBJECT];
 
        # doing something here

        $poe_kernel->yield('send_data', $frame);

    }

=head2 connection_down

This event and corresponding method is a hook to allow you to be notified if 
the connection to the server is currently down. By default it does nothing. 
But it would be useful to notify "gather_data" to temporarily stop doing 
whatever it is currently doing.

 Example

    sub connection_down {
        my ($self) = @_[OBJECT];

        # do something here

    }

=head2 connection_up

This event and corresponding method is a hook to allow you to be notified 
when the connection to the server up. By default it does nothing. 
But it would be useful to notify "gather_data" to start doing 
whatever it supposed to do.

 Example

    sub connection_up {
       my ($self) = @_[OBJECT];

       # do something here

    }

=head2 session_cleanup

This method is a hook and should be overridden to do "shutdown" stuff. By
default it sends a "DISCONNECT" message to the message queue server.

 Example

    sub session_cleanup {
        my $self = shift;

        # do something here

        $self->SUPER::session_cleanup();

    }

=head2 session_reload

This method is a hook and should be overridden to do "reload" stuff. By
default it executes POE's sig_handled() method.

 Example

    sub session_reload {
        my $self = shift;

        $poe_kernel->sig_handled();

    }

=head1 ACCESSORS

=head2 stomp

This returns an object to the internal XAS::Lib::Stomp::Utils 
object. This is very useful for creating STOMP frames.

 Example

    $frame = $self->stomp->connect(
         -login    => 'testing',
         -passcode => 'testing'
    );

    $poe_kernel->yield('send_data', $frame);

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

 For details on the protocol see L<http://stomp.github.io/>.

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See L<http://dev.perl.org/licenses/> for more information.

=cut
