package XAS::Lib::Net::Client;

our $VERSION = '0.03';

use IO::Socket;
use IO::Select;
use Errno ':POSIX';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  utils     => 'trim dotid',
  accessors => 'handle select attempts',
  mutators  => 'timeout',
  import    => 'class',
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
        Timeout  => $self->timeout,
    ) or do {

        my $errno  = $! + 0;
        my $errstr = $!;

        $self->class->var('ERRNO', $errno);
        $self->class->var('ERRSTR', $errstr);

        $self->throw_msg(
            dotid($self->class) . '.connect.noconnect',
            'connection',
            $self->host,
            $self->port,
            $errstr
        );

    };

    $self->handle->blocking(0);
    $self->{select} = IO::Select->new($self->handle);

}

sub disconnect {
    my $self = shift;

    if ($self->handle->connected) {

        $self->handle->close();

    }

}

sub get {
    my $self = shift;
    my ($length) = $self->validate_params(\@_, [
        { optional => 1, default => 512 }
    ]);

    my $packet  = '';
    my $counter = 0;
    my $working = 1;
    my $read    = 0;
    my $timeout = $self->handle->timeout;

    $self->class->var('ERRNO', 0);
    $self->class->var('ERRSTR', '');

    while ($working) {

        my $buf;

        $self->handle->clearerr();

        if ($self->select->can_read($timeout)) {

            if (my $bytes = $self->handle->sysread($buf, $length)) {

                $self->{buffer} .= $buf;
                $read += $bytes;

                if ($read >= $length) {

                    $working = 0;
                    $packet  = $self->_slurp($length);

                }

            } else {

                if ($self->handle->error) {

                    my $errno  = $! + 0;
                    my $errstr = $!;

                    $self->log->debug("get: errno = $errno");

                    if ($errno == EAGAIN) {

                        $counter++;
                        $working = 0 if ($counter > $self->attempts);

                    } else {

                        $self->class->var('ERRNO', $errno);
                        $self->class->var('ERRSTR', $errstr);

                        $self->throw_msg(
                            dotid($self->class) . '.get',
                            'network',
                            $errstr
                        );

                    }

                }

            }

        } else {

            $working = 0;

        }

    }

    return $packet;

}

sub gets {
    my $self = shift;

    my $packet  = '';
    my $counter = 0;
    my $working = 1;
    my $timeout = $self->handle->timeout;

    $self->class->var('ERRNO', 0);
    $self->class->var('ERRSTR', '');

    while ($working) {

        my $buf;

        $self->handle->clearerr();

        if ($self->select->can_read($timeout)) {

            if ($self->handle->sysread($buf, 512)) {

                $self->{buffer} .= $buf;

                if ($packet = $self->_get_line()) {

                    $working = 0;

                }

            } else {

                if ($self->handle->error) {

                    my $errno  = $! + 0;
                    my $errstr = $!;

                    $self->log->debug("get: errno = $errno");

                    if ($errno == EAGAIN) {

                        $counter++;
                        $working = 0 if ($counter > $self->attempts);

                    } else {

                        $self->class->var('ERRNO', $errno);
                        $self->class->var('ERRSTR', $errstr);

                        $self->throw_msg(
                            dotid($self->class) . '.get',
                            'network',
                            $errstr
                        );

                    }

                }

            }

        } else {

            $working = 0;

        }

    }

    return $packet;

}

sub put {
    my $self = shift;
    my ($buffer) = $self->validate_params(\@_, [1]);

    my $written = $self->_put($buffer);

    return $written;

}

sub puts {
    my $self = shift;
    my ($buffer) = $self->validate_params(\@_, [1]);

    my $data = sprintf("%s%s", trim($buffer), $self->eol);
    my $written = $self->_put($data);
    
    return $written;

}

sub errno {
    my $class = shift;
    my ($value) = XAS::Base->validate_params(\@_, [
        { optional => 1, default => undef }
    ]);

    class->var('ERRNO', $value) if (defined($value));

    return class->var('ERRNO');

}

sub errstr {
    my $class = shift;
    my ($value) = XAS::Base->validate_params(\@_, [
        { optional => 1, default => undef }
    ]);

    class->var('ERRSTR', $value) if (defined($value));

    return class->var('ERRSTR');

}

sub setup {
    my $self = shift;
    
}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _put {
    my $self   = shift;
    my $buffer = shift;
    
    my $counter = 0;
    my $working = 1;
    my $written = 0;
    my $timeout = $self->timeout;
    my $bufsize = length($buffer);

    $self->class->var('ERRNO', 0);
    $self->class->var('ERRSTR', '');

    while ($working) {

        $self->handle->cleaerr();

        if ($self->select->can_write($timeout)) {

            if (my $bytes = $self->handle->syswrite($buffer, $bufsize)) {

                $written += $bytes;
                $buffer = substr($buffer, $bytes);
                $working = 0 if ($written >= $bufsize);

            } else {

                if ($self->handle->error) {

                    my $errno  = $! + 0;
                    my $errstr = $!;

                    if ($errno = EAGAIN) {

                        $counter++;
                        $working = 0 if ($counter > $self->attempts);

                    } else {

                        $self->class->var('ERRNO', $errno);
                        $self->class->var('ERRSTR', $errstr);

                        $self->throw_msg(
                            dotid($self->class) . '.put',
                            'network',
                            $errstr
                        );

                    }

                }

            }

        } else {

            $working = 0;

        }

    }

    return $written;

}

sub _slurp {
    my $self = shift;
    my $pos  = shift;

    my $buffer;

    if ($buffer = substr($self->{buffer}, 0, $pos)) {

        substr($self->{buffer}, 0, $pos) = '';

    }

    return $buffer;

}

sub _get_line {
    my $self = shift;

    my $pos;
    my $buffer;
    my $eol = $self->eol;

    if ($self->{buffer} =~ m/$eol/g) {

        $pos = pos($self->{buffer});
        $buffer = $self->_slurp($pos);

    }

    return $buffer;

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{attempts} = 5;
    $self->{buffer}   = '';

    return $self;

}

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

=head2 put($buffer)

This writes a buffer to the socket. Returns the number of bytes written.

=over 4

=item B<$buffer>

The buffer to send over the socket.

=back

=head2 puts($buffer)

This writes a buffer that is terminated with eol to the socket. Returns the
number of bytes written.

=over 4

=item B<$buffer>

The buffer to send over the socket.

=back

=head2 get($length)

This block reads data from the socket. A buffer is returned when it reaches
$length or timeout, whichever is first.

=over 4

=item B<$length>

An optional length for the buffer. Defaults to 512 bytes.

=back

=head2 gets

This reads a buffer delimited by the eol from the socket.

=head2 errno

A class method to return the error number.

=head2 errstr

A class method to return the error string.

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
