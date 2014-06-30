package XAS::Lib::SSH::Client;

our $VERSION = '0.01';

use IO::Select;
use Errno 'EAGAIN';
use Net::SSH2 ':all';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  accessors => 'ssh chan sock select',
  mutators  => 'attempts', 
  vars => {
    PARAMS => {
      -port      => { optional => 1, default => 22 },
      -timeout   => { optional => 1, default => 0.2 },
      -username  => { optional => 1, default => undef},
      -server    => { optional => 1, default => 'localhost' },
      -password  => { optional => 1, default => undef, depends => [ '-username' ] },
      -priv_key  => { optional => 1, default => undef, depends => [ '-pub_key', '-username' ] },
      -pub_key   => { optional => 1, default => undef, depends => [ '-priv_key', '-username' ] },
    },
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub connect {
    my $self = shift;

    my ($errno, $name, $errstr);

    if ($self->ssh->connect($self->server, $self->port)) {

        if ($self->pub_key) {

            unless ($self->ssh->auth_publickey($self->username,
                $self->pub_key, $self->priv_key, $self->password)) {

                ($errno, $name, $errstr) = $self->ssh->error();
                $self->throw_msg(
                    'xas.lib.ssh.client.connect.autherr',
                    'autherr',
                    $name, $errstr
                );

            }

        } else {

            unless ($self->ssh->auth_password($self->username, $self->password)) {

                ($errno, $name, $errstr) = $self->ssh->error();
                $self->throw_msg(
                    'xas.lib.ssh.client.connect.autherr',
                    'autherr',
                    $name, $errstr
                );

            }

        }

        $self->{sock}   = $self->ssh->sock();
        $self->{chan}   = $self->ssh->channel();
        $self->{select} = IO::Select->new($self->sock);

        $self->setup();

    } else {

        ($errno, $name, $errstr) = $self->ssh->error();
        $self->throw_msg(
            'xas.lib.ssh.client.connect.conerr',
            'conerr',
            $name, $errstr
        );

    }

}

sub setup {
    my $self = shift;

    warn "setup() needs to be overridden\n";

}

sub disconnect {
    my $self = shift;

    if (defined($self->chan)) {

        $self->chan->send_eof();
        $self->chan->close();

    }

    $self->ssh->disconnect();

}

sub get {
    my $self = shift;

    my $counter = 0;
    my $output = '';
    my $working = 1;

    # Setup non-blocking read. Keep reading until nothing is left.
    # Return the raw output, if any. 
    #
    # Patterned after some libssh2 examples and C network programming
    # "best practices".

    $self->chan->blocking(0);

    while ($working) {

        my $buf;

        if ($self->chan->read($buf, 512)) {

            $output .= $buf;

        } else {

            my $syserr = $! + 0;
            my ($errno, $name, $errstr) = $self->ssh->error();
            if (($errno == LIBSSH2_ERROR_EAGAIN) || ($syserr == EAGAIN)) {

                $counter++;
 
                $working = 0         if ($counter > $self->attempts);
                $self->_waitsocket() if ($counter <= $self->attempts);

            } else {

                $self->chan->blocking(1);
                $self->throw_msg(
                    'xas.lib.ssh.client.get.protoerr',
                    'protoerr',
                    $name, $errstr
                );

            }

        }

    }

    $self->chan->blocking(1);

    return $output;

}

sub put {
    my $self = shift;
    my ($buffer) = validate_pos(@_, 1);

    my $counter = 0;
    my $working = 1;
    my $written = 0;
    my $bufsize = length($buffer);

    # Setup non-blocking writes. Keep writting until nothing is left.
    # Returns the number of bytes written, if any.
    #
    # Patterned after some libssh2 examples and C network programming
    # "best practices".

    $self->chan->blocking(0);

    do {

        if (my $bytes = $self->chan->write($buffer)) {

            $written += $bytes;
            $buffer  = substr($buffer, $bytes);
            $working = 0 if ($written >= $bufsize);

        } else {

            my ($errno, $name, $errstr) = $self->ssh->error();
            if ($errno == LIBSSH2_ERROR_EAGAIN) {

                $counter++;

                $working = 0         if ($counter > $self->attempts);
                $self->_waitsocket() if ($counter <= $self->attempts);

            } else {

                $self->chan->blocking(1);
                $self->throw_msg(
                    'xas.lib.ssh.client.put.protoerr',
                    'protoerr',
                    $name, $errstr
                );

            }

        }

    } while ($working);

    $self->chan->blocking(1);

    return $written;

}

sub DESTROY {
    my $self = shift;

    $self->disconnect();

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{ssh} = Net::SSH2->new();

    $self->attempts(5);       # number of EAGAIN attempts

    return $self;

}

sub _waitsocket {
    my $self = shift;

    my $to  = $self->timeout;
    my $dir = $self->ssh->block_directions();

    # If $dir is 1, then input  is blocking.
    # If $dir is 2, then output is blocking.
    #
    # Patterned after some libssh2 examples.

    if ($dir == 1) {

        $self->select->can_read($to);

    } else {

        $self->select->can_write($to);

    }

    return $! + 0;

}

1;

__END__

=head1 NAME

XAS::Lib::SSH::Client - A SSH based client

=head1 SYNOPSIS

 use XAS::Lib::SSH::Client;

 my $client = XAS::Lib::SSH::Client->new(
    -server   => 'auburn-xen-01',
    -username => 'root',
    -password => 'secret',
 );

 $client->connect();
 
 $client->put($data);
 $data = $client->get();

 $client->disconnect();

=head1 DESCRIPTION

The module provides basic network connectivity along with input/output methods
using the SSH protocol. It can authenticate using username/password or
username/public key/private key/password. 

=head1 METHODS

=head2 new

This initializes the object. It takes the following parameters:

=over 4

=item B<-username>

An optional username to use when connecting to the server.

=item B<-password>

An optional password to use for authentication.

=item B<-pub_key>

An optional public ssh key file to use.

=item B<-priv_key>

An optional private ssh key to use.

=item B<-server>

The server to connect too. Defaults to 'localhost'.

=item B<-port>

The port to use on the server. It defaults to 22.

=item B<-timeout>

The number of seconds to timeout writes. It must be compatible with IO::Select.
Defaults to 0.2.

=back

=head2 connect

This method makes a connection to the server.

=head2 setup

This method sets up the channel to be used. It needs to be overridden
to be useful.

=head2 get

This method reads date from the channel. It uses non-blocking reads. It
will attempt to read all pending data.

=head2 put($buffer)

This method will write data to the channel. It uses non-blocking writes.
It will attempt to write all the data in the buffer.

=over 4

=item B<$buffer>

The buffer to be written.

=back

=head2 disconnect

This method closes the connection.

=head1 MUTATORS

=head2 attempts

This is used when reading data from the channel. It triggers how many
times to attempt reading from the channel when a LIBSSH2_ERROR_EAGAIN
error occurs. The default is 5 times.

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
