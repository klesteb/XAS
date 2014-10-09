package XAS::Lib::Mixins::JSON::Server;

our $VERSION = '0.04';

use POE;
use Try::Tiny;
use Set::Light;
use Params::Validate 'ARRAYREF';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  mixin     => 'XAS::Lib::Mixins::Handlers',
  accessors => 'methods',
  codec     => 'JSON',
  constants => 'HASH ARRAY :jsonrpc',
  mixins    => 'process_request process_response process_errors 
                _rpc_request _rpc_result _rpc_error methods init_json_server',
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

sub init_json_server {
    my $self = shift;
    my ($methods) = $self->validate_params(\@_, [
        { type => ARRAYREF }
    ]);

    $self->{methods} = Set::Light->new(@$methods);

}

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

sub process_request {
    my ($self, $input, $ctx) = @_[OBJECT,ARG0,ARG1];

    my $request;
    my $alias = $self->alias;

    $self->log->debug("$alias: entering process_request");

    try {

        $request = decode($input);

        if (ref($request) eq ARRAY) {

            foreach my $r (@$request) {

                $self->_rpc_request($r, $ctx);

            }

        } else {

            $self->_rpc_request($request, $ctx);

        }

    } catch {

        my $ex = $_;

        $self->exception_handler($ex);
        $self->log->error(Dumper($input));

    };

}

sub process_response {
    my ($self, $output, $ctx) = @_[OBJECT,ARG0,ARG1];

    my $json;
    my $alias = $self->alias;

    $self->log->debug("$alias: entering process_response");

    $json = $self->_rpc_result($ctx->{id}, $output);

    $poe_kernel->post($alias, 'client_output', encode($json), $ctx);

}

sub process_errors {
    my ($self, $output, $ctx) = @_[OBJECT,ARG0,ARG1];

    my $json;
    my $alias = $self->alias;

    $self->log->debug("$alias: entering process_errors");

    $json = $self->_rpc_error($ctx->{id}, $output->{code}, $output->{message});

    $poe_kernel->post($alias, 'client_output', encode($json), $ctx);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _exception_handler {
    my ($self, $ex, $id) = @_;

    my $packet;
    my $ref = ref($ex);

    if ($ref) {

        if ($ex->isa('XAS::Exception')) {

            my $type = $ex->type;
            my $info = $ex->info;

            if ($type eq ('xas.lib.mixins.json.server.rpc_method')) {

                $packet = $self->_rpc_error($id, RPC_ERR_METHOD, $info);

            } elsif ($type eq ('xas.lib.mixins.json.server.rpc_version')) {

                $packet = $self->_rpc_error($id, RPC_ERR_REQ, $info);

            } elsif ($type eq ('xas.lib.mixins.json.server.rpc_format')) {

                $packet = $self->_rpc_error($id, RPC_ERR_PARSE, $info);

            } elsif ($type eq ('xas.lib.mixins.json.server.rpc_notify')) {

                $packet = $self->_rpc_error($id, RPC_ERR_INTERNAL, $info);

            } else {

                my $msg = $type . ' - ' . $info;
                $packet = $self->_rpc_error($id, RPC_ERR_APP, $msg);

            }

            $self->log->error($self->message('exception', $type, $info));

        } else {

            my $msg = sprintf("%s", $ex);

            $packet = $self->_rpc_error($id, RPC_ERR_SERVER, $msg);
            $self->log->error($self->message('unexpected', $msg));

        }

    } else {

        my $msg = sprintf("%s", $ex);

        $packet = $self->_rpc_error($id, RPC_ERR_APP, $msg);
        $self->log->error($self->message('unexpected', $msg));

    }

    return $packet;

}

sub _rpc_request {
    my ($self, $request, $ctx) = @_;

    my $method;
    my $alias = $self->alias;
    
    try {

        if (ref($request) ne HASH) {

            $self->throw_msg(
                'xas.lib.mixins.json.server.format', 
                'json_rpc_format'
            );

        }

        if ($request->{jsonrpc} ne RPC_JSON) {

            $self->throw_msg(
                'xas.lib.mixins.json.server.rpc_version', 
                'json_rpc_version'
            );

        }

        unless (defined($request->{id})) {

            $self->throw_msg(
                'xas.lib.mixins.json.server.nonotifications', 
                'json_rpc_nonotify'
            );

        }

        if ($self->methods->has($request->{method})) {

            $ctx->{id} = $request->{id};
            $self->log->debug("$alias: performing \"" . $request->{method} . '"');

            $poe_kernel->post($alias, $request->{method}, $request->{params}, $ctx);

        } else {

            $self->throw_msg(
                'xas.lib.mixins.json.server.rpc_method', 
                'json_rpc_method', 
                $request->{method}
            );

        }

    } catch {

        my $ex = $_;

        my $output = $self->_exception_handler($ex, $request->{id});
        $poe_kernel->post($alias, 'client_output', encode($output), $ctx);

    };

}

sub _rpc_error {
    my ($self, $id, $code, $message) = @_;

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

sub _rpc_result {
    my ($self, $id, $result) = @_;

    return {
        jsonrpc => RPC_JSON,
        id      => $id,
        result  => $result
    };

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

         $self->enable_keepalive($socket) if ($self->tcp_keepalive);

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
     my @methods = ('echo');

     $self->init_json_server(\@methods);

     $self->init_keepalive() if ($self->tcp_keepalive);

     return $self;

 }

 package main;

     my $echo = Echo->new();

     $echo->run();

=head1 DESCRIPTION

This modules implements a simple JSON RPC v2.0 server as a mixin. It 
doesn't support "Notification" calls. 

=head1 METHODS

=head2 init_json_server($methods)

This initializes the module.

=over 4

=item B<$methods>

An arrayref of methods that this server can process.

=back

=head2 methods

A handle to a L<Set::Light> object that contains the methods 
that can be evoked.

=head1 EVENTS

=head2 process_request(OBJECT, ARG0, ARG1)

=head2 process_response(OBJECT, ARG0, ARG1)

=head2 process_errors(OBJECT, ARG0, ARG1)

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See L<http://dev.perl.org/licenses/> for more information.

=cut
