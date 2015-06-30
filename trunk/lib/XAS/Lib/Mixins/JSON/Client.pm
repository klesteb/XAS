package XAS::Lib::Mixins::JSON::Client;

our $VERSION = '0.02';

use Params::Validate 'HASHREF';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  codec     => 'JSON',
  constants => ':jsonrpc',
  mixins    => 'call',
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub call {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -method => 1,
        -id     => 1,
        -params => { type => HASHREF }
    });

    my $params;
    my $response;

    while (my ($key, $value) = each(%{$p->{'params'}})) {

        $key =~ s/^-//;
        $params->{$key} = $value;

    }

    my $packet = {
        jsonrpc => RPC_JSON,
        id      => $p->{'id'},
        method  => $p->{'method'},
        params  => $params
    };

    $self->puts(encode($packet));
    $response = $self->gets();

    $response = decode($response);

    if ($response->{id} eq $p->{'id'}) {

        if ($response->{error}) {

            if ($response->{error}->{code} eq RPC_ERR_APP) {

                my ($type, $info) = split(' - ', $response->{error}->{data});

                $self->throw_msg(
                    $type,
                    'json_rpc_errorapp',
                    $info
                );

            } else {

                $self->throw_msg(
                    'xas.lib.mixin.json.client',
                    'json_rpc_error',
                    $response->{error}->{code},
                    $response->{error}->{message},
                    $response->{error}->{data}
                );

            }

        }

    } else {

        $self->throw_msg(
            'xas.lib.mixin.json.client',
            'rpc_invalid_id',
        );

    }

    return $response->{result};

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Mixins::JSON::Client - A mixin for a JSON RPC interface

=head1 SYNOPSIS
 
 package Client

 use XAS::Class
     debug   => 0,
     version => '0.01',
     base    => 'XAS::Lib::Net::Client',
     mixin   => 'XAS::Lib::Mixins::JSON::Client',
 ;

 package main

  my $client = Client->new(
     -port => 9505,
     -host => 'localhost',
 );
 
 $client->connect();
 
 my $data = $client->call(
     -method => 'test'
     -id     => $id,
     -params => {}
 );
 
 $client->disconnect();
 
=head1 DESCRIPTION

This modules implements a simple L<JSON RPC v2.0|http://www.jsonrpc.org/specification> client as a mixin. It 
doesn't support "Notification" calls.

=head1 METHODS

=head2 call

This method is used to format the JSON packet and send it to the server. 
Any errors returned from the server are parsed and then thrown.

=over 4

=item B<-method>

The name of the RPC method to invoke.

=item B<-id>

The id used to identify this method call.

=item B<-params>

A hashref of the parameters to be passed to the method.

=back

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
