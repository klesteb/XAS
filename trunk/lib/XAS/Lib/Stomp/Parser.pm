package XAS::Lib::Stomp::Parser;

our $VERSION = '0.01';

use XAS::Lib::Stomp::Frame;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  utils     => 'trim',
  accessors => 'target',
  vars => {
    PARAMS => {
      -target  => { optional => 1, default => '1.0', regex => qr/(1\.0|1\.1|1\.2)/ },
    }
  }
;

our $EOF    = "\000";
our $CNTRL  = qr((?:[[:cntrl:]])+);
our $HEADER = qr(([\w\-~]+)\s*:\s*(.*));
our $EOL    = qr((\015\012?|\012\015?|\015|\012));
our $BEOH   = qr((\015\012\000?|\012\015\000?|\015\000|\012\000));
our $EOH    = qr((\015\012\015\012?|\012\015\012\015?|\015\015|\012\012));

#use Data::Dumper;
#use Data::Hexdumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub parse {
    my $self   = shift;
    my $buffer = shift;

    my $line;
    my $length;
    my $clength;
    my $count = 0;
    my $frame = undef;

    $self->{buffer} .= $buffer;

    $self->log->debug('buffer');
#    $self->log->debug(hexdump($self->{buffer}));

    # A valid frame is usually this:
    #
    # command<eol>    - command
    # header<eol>     - 0 or more
    # <eol>           - seperator
    # body<eof>       - body
    #
    # as of v1.1 this is a valid frame
    #
    # <eol><eol><eol><eof>
    #
    # and is used as a NOOP, which is used as a protocol keepalive. This
    # module will create a fake 'NOOP' command for that frame. Frame
    # stringification does the right thing.
    #
    # All current versions define <eof> as \000.
    #
    # In v1.0 and v1.1, <eol> was defined as NEWLINE, which is \012, but, 
    # common usage was \n, which is platform specific, hence the $EOL, $EOH
    # and $BEOH regexs to match against.
    #
    # v1.2 changes <eol> to \015\012
    #

    for (;;) {

        $self->log->debug('state = ' . $self->{state});

        if ($self->{state} eq 'command') {

            # start of the frame 
            # check for a valid buffer, must have a EOL someplace.

            if ($line = $self->_read_line($EOL)) {

                $self->log->debug('command');
#                $self->log->debug(hexdump($line));

                $line = trim($line);

                $self->{command} = ($line eq '') ? 'NOOP' : $line;
                $self->{state} = 'headers';

            } else { last; }

        } elsif ($self->{state} eq 'headers') {

            # start of the headers, they last until a standalone <eol>
            # or <eof> is reached. 

            $self->log->debug("header");

            $length = length($self->{buffer});

            $self->{buffer} =~ m/$EOH/g;
            $clength = pos($self->{buffer}) || -1;

            $self->log->debug("end of headers $clength");

            if ($clength == -1) {

                pos($self->{buffer}) = 0;
                $self->{buffer} =~ m/$BEOH/g;
                $clength = pos($self->{buffer}) || -1;

                $self->log->debug("end of frame $clength");

            }

            if (($clength != -1) && ($clength <= $length)) {

                $line = $self->_slurp($clength);
#                $self->log->debug(hexdump($line));

                while ($line =~ s/^$HEADER//) {

                    $self->log->debug('valid header');

                    my $key   = lc($1);
                    my $value = trim($2);

                    # v1.2 says that the first defined header is
                    # to be honored. v1.0 and v1.1 implies that
                    # the last defined header is honored. The duplictes
                    # are discarded.

                    if ($self->target < 1.2) {

                        $self->{headers}->{$key} = $value;

                    } else {

                        unless (defined($self->{headers}->{$key})) {

                            $self->{headers}->{$key} = $value;

                        }

                    }

                    $line =~ s/$EOL//;

                }

                $self->{state} = 'body';

            } else { last; }

        } elsif ($self->{state} eq 'body') {

            $self->log->debug('body');

            # start of the body, determine wither to use
            # content-length or EOF to find the end 

            $length = length($self->{buffer});

            if ($clength = $self->{headers}->{'content-length'}) {

                $self->log->debug('using content-length');

                if ($clength <= $length) {

                    $self->{body} = $self->_slurp($clength);
                    $self->{state} = 'frame';

                } else { last; }

            } else {

                $self->log->debug('using EOF');

                $clength = index($self->{buffer}, $EOF);

                if (($clength != -1) && ($clength <= $length)) {

                    $self->{body} = $self->_read_line($EOF);
                    chop $self->{body};
                    $self->{state} = 'frame';

                } else { last; }

            }

        } elsif ($self->{state} eq 'frame') {

            $self->log->debug('building frame');

            # clear out inter-frame crap and create the object.

            $self->{buffer} =~ s/^$CNTRL//;

            $frame = XAS::Lib::Stomp::Frame->new(
                -target  => $self->target,
                -command => $self->{command},
                -headers => $self->{headers},
                -body    => $self->{body}
            );

            # reset ourselves

            $count = 0;

            delete $self->{command};
            delete $self->{headers};
            delete $self->{body};

            $self->{state} = 'command';

        }

    }

    return $frame;

}

sub get_pending {
    my $self = shift;

    return $self->{buffer};

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);
    
    $self->{state} = 'command';

    return $self;

}

sub _read_line {
    my $self = shift;
    my $eol  = shift;

    my $pos;
    my $buffer;

    if ($self->{buffer} =~ m/$eol/g) {

        $pos = pos($self->{buffer});
        $buffer = $self->_slurp($pos);

    }

    return $buffer;

}

sub _slurp {
    my $self = shift;
    my $pos  = shift;

    my $buffer;

    if ($buffer = substr($self->{buffer}, 0, $pos)) {

        substr($self->{buffer}, 0, $pos) = "";

    }

    return $buffer;

}

1;

__END__

=head1 NAME

XAS::Lib::Stomp::Parse - Create a STOMP Frame From a Buffer

=head1 SYNOPSIS

  use XAS::Lib::Stomp::Parser;

  my $parser = XAS::Lib::Stomp::Parser->new(
    -target  => '1.0',
  );

  while (my $buffer = read()) {

     if (my $frame = $parser->parse($buffer)) {

         # do something...

     }

  }

=head1 DESCRIPTION

This module creates STOMP frames from a buffer. STOMP is the 
Streaming Text Orientated Messaging Protocol (or the Protocol Briefly 
Known as TTMP and Represented by the symbol :ttmp). It's a simple and easy to
implement protocol for working with Message Orientated Middleware from
any language. This module supports v1.0, v1.1 and v1.2 frames with limited
interoperability between the frame types.

A STOMP frame consists of a command, a series of headers and a body.

=head1 METHODS

=head2 new

Creates a new parser. It can take the following parameters:

=over 4

=item B<-target>

Specify a STOMP protocol version number. It currently supports 1.0,
1.1 and 1.2, defaulting to 1.0.

=back

=head2 get_pending

Returns the contents of the internal buffer.

=head1 SEE ALSO

=over 4

=item L< XAS|XAS>

=back

For more information on the STOMP protocol, please refer to: L<http://stomp.github.io/> .

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See L<http://dev.perl.org/licenses/> for more information.

=cut
