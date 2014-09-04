package XAS::Lib::Net::Client;

our $VERSION = '0.03';

use IO::Socket;
use Params::Validate ':all';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  utils     => 'trim',
  accessors => 'handle',
  mutators  => 'timeout',
  import    => 'class',
  messages => {
    connection => "unable to connect to %s on port %s, reason: %s",
    network    => "a network communication error has occured, reason: %s",
  },
  vars => {
    PARAMS => {
      -port    => 1,
      -host    => 1,
      -timeout => { optional => 1, default => 60 },
      -eol     => { optional => 1, default => "\012\015" },
    },
    ERRNO  => 0,
    ERRSTR => '',
  }
;

#use Data::Hexdumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub connect {
    my $self = shift;

    $self->class->var('ERRNO', 0);
    $self->class->var('ERRSTR', '');

    $self->{handle} = IO::Socket::INET->new(
        Proto    => 'tcp',
        PeerPort => $self->port,
        PeerAddr => $self->host,
    ) or do {

        my $errno = $! + 0;
        my $errstr = $!;

        $self->class->var('ERRNO', $errno);
        $self->class->var('ERRSTR', $errstr);

        $self->throw_msg(
            'xas.lib.net.client.connect.noconnect',
            'connection',
            $self->host,
            $self->port,
            $errstr
        );

    };

}

sub disconnect {
    my $self = shift;

    if ($self->handle->connected) {

        $self->handle->close();

    }

}

sub get {
    my $self = shift;

    my $packet = '';
    my $timeout = $self->handle->timeout;

    $self->handle->timeout($self->timeout) if ($self->timeout);

    # temporarily set the INPUT_RECORD_SEPERATOR

    local $/ = $self->eol;

    $self->handle->clearerr();
    $self->class->var('ERRNO', 0);
    $self->class->var('ERRSTR', '');
    $packet = $self->handle->getline() || '';

    chomp($packet);

#    $self->log('debug', hexdump($packet));

    if ($self->handle->error) {

        my $errno = $! + 0;
        my $errstr = $!;

        $self->class->var('ERRNO', $errno);
        $self->class->var('ERRSTR', $errstr);

        $self->throw_msg(
            'xas.lib.net.client.get',
            'network',
            $errstr
        );

    }

    $self->handle->timeout($timeout);

    return $packet;

}

sub put {
    my $self = shift;
    my ($packet) = validate_pos(@_, 1, );

    my $timeout = $self->handle->timeout;

    $self->handle->timeout($self->timeout) if ($self->timeout);
    $self->handle->clearerr();
    $self->class->var('ERRNO', 0);
    $self->class->var('ERRSTR', '');
    $self->handle->printf("%s%s", trim($packet), $self->eol);

    if ($self->handle->error) {

        my $errno = $! + 0;
        my $errstr = $!;

        $self->class->var('ERRNO', $errno);
        $self->class->var('ERRSTR', $errstr);

        $self->throw_msg(
            'xas.lib.net.client.put',
            'network',
            $errstr
        );

    }

    $self->handle->timeout($timeout);

}

sub errno {
    my ($class, $value) = validate_pos(@_,
        1,
        { optional => 1, default => undef }
    );

    if (defined($value)) {

        class->var('ERRNO', $value);

    }

    return class->var('ERRNO');

}

sub errstr {
    my ($class, $value) = validate_pos(@_,
        1,
        { optional => 1, default => undef }
    );

    if (defined($value)) {

        class->var('ERRSTR', $value);

    }

    return class->var('ERRSTR');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Net::Client - The network client interface for the XAS environment

=head1 SYNOPSIS

 my $rpc = XAS::Lib::Net::Client->new(
   -port => 9505,
   -host => 'localhost',
 };

=head1 DESCRIPTION

This module implements a simple text orientated network protocol. All "packets"
will have an explicit "\012\015" appended. This delineates the "packets" and is
network neutral. No attempt is made to decipher these "packets".

=head1 METHODS

=head2 new

This initializes the module and can take these parameters. It doesn't actually
make a network connection.

=over 4

=item B<-port>

The port number to attach too.

=item B<-host>

The host to use for the connection. This can be an IP address or
a host name.

=item B<-timeout>

An optional timeout, it defaults to 60 seconds.

=item B<-eol>

An optional eol. The default is "\012\015". Which is network netural.

=back

=head2 connect

Connect to the defined socket.

=head2 disconnect

Disconnect from the defined socket.

=head2 put($packet)

This writes a "packet" to the socket.

=over 4

=item B<$packet>

The "packet" to send over the socket.

=back

=head2 get

This reads a "packet" from the socket.

=head2 errno

A class method to return the error number code.

=head2 errstr

A class method to return the error number string.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

Copyright (C) 2014 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See L<http://dev.perl.org/licenses/> for more information.

=cut
