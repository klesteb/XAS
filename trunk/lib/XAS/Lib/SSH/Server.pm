package XAS::Lib::SSH::Server;

our $VERSION = '0.01';

use POE;
use POE::Filter::Line;
use POE::Wheel::ReadWrite;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::Service',
  accessors =>'client filter host port',
  vars => {
    PARAMS => {
      -filter => { optional => 1, default => undef },
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

    $self->{host} = $rhost;
    $self->{port} = $rport;

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

sub session_pause {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_pause()");

    $self->client->pause_input();

    # walk the chain

    $self->SUPER::session_pause();

    $self->log->debug("$alias: entering session_pause()");

}

sub session_resume {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_resume()");

    $self->client->resume_input();

    # walk the chain

    $self->SUPER::session_resume();

    $self->log->debug("$alias: leaving session_resume()");

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

    if (my $wheel = $ctx->{wheel})) {

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

        $self->log->info_msg('client_disconnect', $alias, $self->host(), $self->port()));

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
            InputLiteral  => "\012\015",
            OutputLiteral => "\012\015"
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

 my $sub = XAS::Lib::SSH::Server->new();

 $sub->run();

=head1 DESCRIPTION

The module provides basic I/O for a SSH subsystem. A SSH subsystem reads from
stdin, writes to stdout and stderr.

=head1 METHODS

=head2 new

This initializes the object.

=head2 connect

This method redirects the stdin, stdout and stderr file streams
to the SSH server.

=head2 get

This method reads data from stdin. It uses blocking reads. It
will attempt to read all pending data up to EOL.

=head2 put($buffer)

This method will write data to stdout. It uses blocking writes.
It will attempt to write all the data in the buffer.

=over 4

=item B<$buffer>

The buffer to be written.

=back

=head2 disconnect

This method closes the connection.

=head1 MUTATORS

=head2 eol

This method sets the EOL for reads. It defaults to LF - "\012".

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
