package XAS::Lib::Mixins::JSON::Server;

our $VERSION = '0.04';

use POE;
use Try::Tiny;
use Set::Light;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  mixin     => 'XAS::Lib::Mixins::Handlers',
  utils     => ':validation dotid',
  accessors => 'methods',
  codec     => 'JSON',
  constants => 'HASH ARRAY :jsonrpc ARRAYREF HASHREF',
  mixins    => 'process_request process_response process_errors 
                methods init_json_server rpc_exception_handler
                rpc_request rpc_error rpc_result',
;

my $errors = {
    '-32700' => 'Parse Error',
    '-32600' => 'Invalid Request',
    '-32601' => 'Method not Found',
    '-32602' => 'Invalid Params',
    '-32603' => 'Internal Error',
    '-32099' => 'Server Error',
    '-32001' => 'App Error',
};

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

sub process_request {
    my $self = shift;
    my ($input, $ctx) = validate_params(\@_, [
        1,
        { type => HASHREF }
    ]);

    my $request;
    my $alias = $self->alias;

    $self->log->debug("$alias: entering process_request");
    $self->log->debug(Dumper($input));

    try {

        $request = decode($input);

        if (ref($request) eq ARRAY) {

            foreach my $r (@$request) {

                $self->rpc_request($r, $ctx);

            }

        } else {

            $self->rpc_request($request, $ctx);

        }

    } catch {

        my $ex = $_;

        $self->log->error(Dumper($input));
        $self->exception_handler($ex);

    };

}

sub process_response {
    my $self = shift;
    my ($output, $ctx) = validate_params(\@_, [
        1,
        { type => HASHREF }
    ]);

    my $json;
    my $alias = $self->alias;

    $self->log->debug("$alias: entering process_response");

    $json = $self->rpc_result($ctx->{'id'}, $output);

    $poe_kernel->post($alias, 'client_output', encode($json), $ctx);

}

sub process_errors {
    my $self = shift;
    my ($error, $ctx) = validate_params(\@_, [
        { type => HASHREF },
        { type => HASHREF }
    ]);

    my $json;
    my $alias = $self->alias;

    $self->log->debug("$alias: entering process_errors");

    $json = $self->rpc_error($ctx->{'id'}, $error->{'code'}, $error->{'message'});

    $poe_kernel->post($alias, 'client_output', encode($json), $ctx);

}

sub rpc_exception_handler {
    my $self = shift;
    my ($ex, $id) = validate_params(\@_, [1,1]);

    my $packet;
    my $ref = ref($ex);

    if ($ref) {

        if ($ex->isa('XAS::Exception')) {

            my $type = $ex->type;
            my $info = $ex->info;

            if ($type =~ /server\.rpc_method$/) {

                $packet = $self->rpc_error($id, RPC_ERR_METHOD, $info);

            } elsif ($type =~ /server\.rpc_version$/) {

                $packet = $self->rpc_error($id, RPC_ERR_REQ, $info);

            } elsif ($type =~ /server\.rpc_format$/) {

                $packet = $self->rpc_error($id, RPC_ERR_PARSE, $info);

            } elsif ($type =~ /server\.rpc_notify$/) {

                $packet = $self->rpc_error($id, RPC_ERR_INTERNAL, $info);

            } else {

                my $msg = $type . ' - ' . $info;
                $packet = $self->rpc_error($id, RPC_ERR_APP, $msg);

            }

            $self->log->error_msg('exception', $type, $info);

        } else {

            my $msg = sprintf("%s", $ex);

            $packet = $self->rpc_error($id, RPC_ERR_SERVER, $msg);
            $self->log->error_msg('unexpected', $msg);

        }

    } else {

        my $msg = sprintf("%s", $ex);

        $packet = $self->rpc_error($id, RPC_ERR_APP, $msg);
        $self->log->error_msg('unexpected', $msg);

    }

    return $packet;

}

sub rpc_request {
    my $self = shift;
    my ($request, $ctx) = validate_params(\@_, [
        { type => HASHREF },
        { type => HASHREF },
    ]);

    my $method;
    my $alias = $self->alias;
    
    try {

        if ($request->{'jsonrpc'} ne RPC_JSON) {

            $self->throw_msg(
                dotid($self->class) . '.server.rpc_version', 
                'json_rpc_version'
            );

        }

        unless (defined($request->{'id'})) {

            $self->throw_msg(
                dotid($self->class) . '.server.rpc_notify', 
                'json_rpc_notify'
            );

        }

        if ($self->methods->has($request->{'method'})) {

            $ctx->{'id'} = $request->{'id'};
            $self->log->debug("$alias: performing \"" . $request->{'method'} . '"');

            $poe_kernel->post($alias, $request->{'method'}, $request->{'params'}, $ctx);

        } else {

            $self->throw_msg(
                dotid($self->class) . '.server.rpc_method', 
                'json_rpc_method', 
                $request->{'method'}
            );

        }

    } catch {

        my $ex = $_;

        my $output = $self->rpc_exception_handler($ex, $request->{'id'});
        $poe_kernel->post($alias, 'client_output', encode($output), $ctx);

    };

}

sub rpc_error {
    my $self = shift;
    my ($id, $code, $message) = validate_params(\@_, [1,1,1]);

    return {
        jsonrpc => RPC_JSON,
        id      => $id,
        error   => {
            code    => $code,
            message => $errors->{$code},
            data    => $message
        }
    };

}

sub rpc_result {
    my $self = shift;
    my ($id, $result) = validate_params(\@_, [1,1]);

    return {
        jsonrpc => RPC_JSON,
        id      => $id,
        result  => $result
    };

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init_json_server {
    my $self = shift;
    my ($methods) = validate_params(\@_, [
        { type => ARRAYREF }
    ]);

    $self->{'methods'} = Set::Light->new();
    $self->methods->insert($methods);

}

1;

__END__

=head1 NAME

XAS::Lib::Mixins::JSON::Server - A mixin for a simple JSON RPC server

=head1 SYNOPSIS

 package Echo;

 use POE;
 use XAS::Class
   debug   => 0,
   version => '0.01',
   base    => 'XAS::Lib::Net::Server'
   mixin   => 'XAS::Lib::Mixins::JSON::Server XAS::Lib::Mixins::Keepalive',
   vars => {
     PARAMS => {
       -port          => { optional => 1, default => 9500 },
       -tcp_keepalive => { optional => 1, default => 0 }
     }
   }
 ;

 sub handle_connection {
     my ($self, $wheel) = @_[OBJECT, ARG0];

     if (my $socket = $self->{clients}->{$wheel}->{socket}) {

         if ($self->tcp_keepalive) {

             $self->log->info("keepalive enabled");
             $self->init_keepalive();
             $self->enable_keepalive($socket);

         }

     }

 }

 sub echo {
     my ($self, $params, $ctx) = @_[OBJECT, ARGO, ARG1];

     my $alias = $self->alias;
     my $line  = $params->{line};

     $poe_kernel->post($alias, 'process_response', $line, $ctx);

 }

 sub init {
     my $class = shift;

     my $self = $class->SUPER::init(@_);
     my @methods = ['echo'];

     $self->init_json_server(\@methods);

     return $self;

 }

 package main;

     my $echo = Echo->new();

     $echo->run();

=head1 DESCRIPTION

This modules implements a simple L<JSON RPC v2.0|http://www.jsonrpc.org/specification> server as a mixin. It 
doesn't support "Notification" calls. 

=head1 METHODS

=head2 init_json_server($methods)

This initializes the module.

=over 4

=item B<$methods>

An arrayref of methods that this server can process.

=back

=head2 methods

A handle to a L<Set::Light|https://metacpan.org/pod/Set::Light> object that contains the methods 
that can be evoked.

=head2 process_request($input, $ctx)

=head2 process_response($output, $ctx)

=head2 process_errors($errors, $ctx)

=head2 rpc_exception_handler($ex, $id)

=head2 rpc_request($request, $ctx)

=head2 rpc_result($id, $output)

=head2 rpc_error($id, $code, $message)

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
