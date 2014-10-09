package XAS::Lib::RPC::JSON::Client;

our $VERSION = '0.02';

use Params::Validate ':all';

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Lib::Net::Client',
  codec     => 'JSON',
  constants => ':jsonrpc',
  messages => {
    jsonerr  => "error code: %s, reason: %s, extended: %s",
    invid    => "the returned id doesn't match the supplied id",
    errorapp => '%s',
  },
  vars => {
    PARAMS => {
      -port => { optional => 1, default => RPC_DEFAULT_PORT },
      -host => { optional => 1, default => RPC_DEFAULT_ADDRESS },
    }
  }
;

Params::Validate::validation_options(
    on_fail => sub {
        my $params = shift;
        my $class  = __PACKAGE__;
        XAS::Base::validation_exception($params, $class);
    }
);

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub call {
    my $self = shift;

    my %p = validate(@_, {
        -method => 1,
        -id     => 1,
        -params => { type => HASHREF }
    });

    my $params;
    my $response;

    while (my ($key, $value) = each(%{$p{'-params'}})) {

        $key =~ s/^-//;
        $params->{$key} = $value;

    }

    my $packet = {
        jsonrpc => RPC_JSON,
        id      => $p{'-id'},
        method  => $p{'-method'},
        params  => $params
    };

    $self->put(encode($packet));
    $response = $self->get();

    $response = decode($response);

    if ($response->{id} eq $p{'-id'}) {

        if ($response->{error}) {

            if ($response->{error}->{code} eq RPC_ERR_APP) {

                my ($type, $info) = split(' - ', $response->{error}->{data});

                $self->throw_msg(
                    $type,
                    'errorapp',
                    $info
                );

            } else {

                $self->throw_msg(
                    'xas.lib.mixins.json.client',
                    'jsonerr',
                    $response->{error}->{code},
                    $response->{error}->{message},
                    $response->{error}->{data}
                );

            }

        }

    } else {

        $self->throw_msg(
            'xas.lib.mixins.json.client',
            'invid',
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

XAS::Lib::RPC::JSON::Client - A JSON RPC interface for the XAS environment

=head1 SYNOPSIS
 
 my $client = XAS::Lib::RPC::JSON::Client->new(
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

This modules implements a simple JSON RPC v2.0 client. It needs be extended
to be usefull. It doesn't support "Notification" calls.

=head1 METHODS

=head2 new

This initializes the module. There are three parameters that can be passed. 
They are the following:

=over 4

=item B<-port>

The IP port to connect to (default 9505).

=item B<-host>

The host to connect to (default 127.0.0.1).

=item B<-timeout>

An optional timeout, this defaults to 60 seconds.

=back

=head2 connect

Connect to the defined server.

=head2 disconnect

Disconnect from the defined server.

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

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See L<http://dev.perl.org/licenses/> for more information.

=cut
