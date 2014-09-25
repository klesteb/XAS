package XAS::Lib::SSH::Server;

our $VERSION = '0.01';

use POE;
use POE::Filter::Line;
use POE::Wheel::ReadWrite;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::POE::Session',
  accessors => 'client peerhost peerport',
  vars => {
    PARAMS => {
      -filter => { optional => 1, default => undef },
      -eol    => { optional => 1, default => "\012\015" },
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

    # public events

    $poe_kernel->state('process_errors',   $self);
    $poe_kernel->state('process_request',  $self);
    $poe_kernel->state('process_response', $self);

    # private events

    $poe_kernel->state('client_error',  $self, '_client_error');
    $poe_kernel->state('client_input',  $self, '_client_input');
    $poe_kernel->state('client_output', $self, '_client_output');

    # Find the remote host and port.

    my ($rhost, $rport, $lhost, $lport) = split(' ', $ENV{SSH_CONNECTION});

    $self->{peerhost} = $rhost;
    $self->{peerport} = $rport;

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leaving session_intialize()");

}

sub session_startup {
    my $self = shift;

    my $alias = $self->alias;

    # start listening for connections

    $self->log->debug("$alias: entering session_startup()");

    $poe_kernel->post($alias, 'client_connection');

    # walk the chain

    $self->SUPER::session_startup();

    $self->log->debug("$alias: leaving session_startup()");

}

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

sub process_request {
    my ($self, $input, $ctx) = @_[OBJECT,ARG0,ARG1];

    my $output = $input;
    my $alias = $self->alias;

    $self->log->debug("$alias: process_request()");

    $poe_kernel->post($alias, 'process_response', $output, $ctx);

}

sub process_response {
    my ($self, $output, $ctx) = @_[OBJECT,ARG0,ARG1];

    my $alias = $self->alias;

    $self->log->debug("$alias: process_response()");

    $poe_kernel->post($alias, 'client_output', $output, $ctx);

}

sub process_errors {
    my ($self, $output, $ctx) = @_[OBJECT,ARG0,ARG1];

    my $alias = $self->alias;

    $self->log->debug("$alias: process_errors()");

    $poe_kernel->post($alias, 'client_output', $output, $ctx);

}

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _client_connection {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: _client_connection()");

    # Start listening on stdin.

    $self->{client} = POE::Wheel::ReadWrite->new(
        InputHandle  => \*STDIN,
        OutputHandle => \*STDOUT,
        Filter       => $self->filter,
        InputEvent   => 'client_input',
        ErrorEvent   => 'client_error'
    );

}

sub _client_input {
    my ($self, $input, $wheel) = @_[OBJECT,ARG0,ARG1];

    my $alias = $self->alias;
    my $ctx = {
        wheel => $wheel
    };

    $self->log->debug("$alias: _client_input()");

    $poe_kernel->post($alias, 'process_request', $input, $ctx);

}

sub _client_output {
    my ($self, $output, $ctx) = @_[OBJECT,ARG0,ARG1];

    my @packet;
    my $alias = $self->alias;

    push(@packet, $output);

    $self->log->debug("$alias: _client_output()");

    if (my $wheel = $ctx->{wheel}) {

        $wheel->put(@packet);

    } else {

        $self->log->error_msg('nowheel', $alias);

    }

}

sub _client_error {
    my ($self, $syscall, $errnum, $errstr, $wheel) = @_[OBJECT,ARG0 .. ARG3];

    my $alias = $self->alias;

    $self->log->debug("$alias: _client_error()");

    if ($errnum == 0) {

        $self->log->info_msg('client_disconnect', $alias, $self->peerhost, $self->peerport);

    } else {

        $self->log->error_msg('client_error', $alias, $errnum, $errstr);

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
            OutputLiteral => $self->eol
        );

    }

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::SSH::Server - A SSH Subsystem based server

=head1 SYNOPSIS

 use XAS::Lib::SSH::Server;

 my $server = XAS::Lib::SSH::Server->new(
     -filter => POE::Filter::Line->new(),
     -eol    => "\012\015",
 );

 $server->run();

=head1 DESCRIPTION

The module provides a POE based framework for a SSH subsystem. A SSH subsystem
reads from stdin, writes to stdout or stderr. This modules emulates 
L<XAS::Lib::Net::Server> to provide a consistent interface.

=head1 METHODS

=head2 new

This initializes the module and starts listening for requests. The following
parametrs are used:

=over 4

=item B<-alias>

The name of the POE session.

=item B<-filter>

An optional filter to use, defaults to POE::Filter::Line

=item B<-eol>

An optional EOL, defaults to "\012\015";

=back

=head1 ACCESSORS

=head2 peerport

This returns the peers port number.

=head2 peerhost

This returns the peers host name.

=head1 MUTATORS

=head2 eol

This method sets the EOL for reads. It defaults to CRLF - "\015\012".

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
