package XAS::Lib::Pipe;

our $VERSION = '0.01';

my $mixin;

BEGIN {
    $mixin = 'XAS::Lib::Pipe::Unix';
};

use POE;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::POE::Session',
  mixin     => $mixin,
  accessors => 'pipe',
  utils     => ':validation trim dotid',
  vars => {
    PARAMS => {
      -fifo   => { isa => 'Badger::Filesystem::File' },
      -filter => { optional => 1, default => undef },
      -eol    => { optional => 1, default => "\n" },
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

    $self->log->debug("$alias: entering session_initialize()");

    # public events

    # private events

    $poe_kernel->state('pipe_error',      $self, '_pipe_error');
    $poe_kernel->state('pipe_input',      $self, '_pipe_input');
    $poe_kernel->state('pipe_output',     $self, '_pipe_output');
    $poe_kernel->state('pipe_connection', $self, '_pipe_connection');

    $poe_kernel->state('process_errors',   $self, '_process_errors');
    $poe_kernel->state('process_request',  $self, '_process_request');
    $poe_kernel->state('process_response', $self, '_process_response');

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leaving session_initialize()");

}

sub session_startup {
    my $self = shift;

    my $alias = $self->alias;

    # start listening for connections

    $self->log->debug("$alias: entering session_startup()");

    $poe_kernel->post($alias, 'pipe_connection');

    # walk the chain

    $self->SUPER::session_startup();

    $self->log->debug("$alias: leaving session_startup()");

}

sub process_request {
    my $self = shift;
    my ($input) = validate_params(\@_, [1]);

    return $input;

}

sub process_response {
    my $self = shift;
    my ($output) = validate_params(\@_, [1]);

    return $output;

}

sub process_errors {
    my $self = shift;
    my ($output) = validate_params(\@_, [1]);

    return $output;

}

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _process_request {
    my ($self, $input) = @_[OBJECT,ARG0];

    my $alias = $self->alias;
    my $data  = $self->process_request($input);

    $self->log->debug("$alias: process_request()");
    $poe_kernel->post($alias, 'process_response', $data);

}

sub _process_response {
    my ($self, $output) = @_[OBJECT,ARG0];

    my $alias = $self->alias;
    my $data  = $self->process_response($output);

    $self->log->debug("$alias: process_response()");
    $poe_kernel->post($alias, 'pipe_output', $data);

}

sub _process_errors {
    my ($self, $output) = @_[OBJECT,ARG0,ARG1];

    my $alias = $self->alias;
    my $data  = $self->process_errors($output);

    $self->log->debug("$alias: process_errors()");
    $poe_kernel->post($alias, 'pipe_output', $data);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->init_pipe();

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Pipe - Interact with named pipes

=head1 SYNOPSIS

 use XAS::Lib::Pipe;

 my $client = XAS::Lib::Pipe->new(
     -fifo   => File('/var/lib/xas/pipe'),
     -filter => POE::Filter::Line->new(),
     -eol    => "\n",
 );

 $server->run();

=head1 DESCRIPTION

The module provides a POE based framework for reading and writing to named 
pipes. 

=head1 METHODS

=head2 new

This initializes the module and starts listening on the pipe. The following
parametrs are used:

=over 4

=item B<-alias>

The name of the POE session.

=item B<-fifo>

The name of the pipe to interact with.

=item B<-filter>

An optional filter to use, defaults to POE::Filter::Line

=item B<-eol>

An optional EOL, defaults to "\n";

=back

=head2 process_request($input)

This method will process the input from the client. It takes the
following parameters:

=over 4

=item B<$input>

The input received from the socket.

=back

=head2 process_response($output)

This method will process the output from the client. It takes the
following parameters:

=over 4

=item B<$output>

The output to be sent to the socket.

=back

=head2 process_errors($error)

This method will process the error output from the client. It takes the
following parameters:

=over 4

=item B<$error>

The output to be sent to the socket.

=back

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
