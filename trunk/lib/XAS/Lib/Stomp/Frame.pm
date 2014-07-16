package XAS::Lib::Stomp::Frame;

our $VERSION = '0.01';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  accessors => 'eol header',
  mutators  => 'target command body',
  constants => 'CRLF',
  codec     => 'unicode',
  constant => {
      LF  => "\n",
      EOF => "\000",
  },
  vars => {
    PARAMS => {
      -body    => { optional => 1, default => undef },
      -command => { optional => 1, default => undef },
      -headers => { optional => 1, default => undef },
      -target  => { optional => 1, default => '1.0', regex => qr/(1\.0|1\.1|1\.2)/ },
    }
  }
;

our %ENCODE_MAP = (
    "\r" => "\\r",
    "\n" => "\\n",
    ":"  => "\\c",
    "\\" => "\\\\",
);

our %DECODE_MAP = reverse %ENCODE_MAP;

#use Data::Dumper;
#use Data::Hexdumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub as_string {
    my $self = shift;

    # protocol spec is unclear about the case of the command,
    # so uppercase the command, Why, just because I can.

    my $frame;
    my $command = uc($self->command);
    my $headers = $self->header->devolve;
    my $body    = $self->body;

    # special handling for NOOPs

    if ($command eq 'NOOP') {

        $command = '';
        $headers = {};
        $body    = '';

    }

    if ($self->target > 1.1) {

        $frame = encode('utf8', $command) . $self->eol;

    } else {

        $frame = $command . $self->eol;

    }

    # v1.0 and v1.1 is unclear about spaces between headers and values 
    # nor the case of the header.
    #
    # v1.2 says there should be no 'padding' in headers and values, not 
    # sure what 'padding' means. It also adds the capability to 'escape'
    # certain values. Please see %ENCODE_MAP and %DECODE_MAP for those
    # values.
    #
    # So add a space and lowercase the header. Why, just because I can.

    if (keys %{$headers}) {

        $self->_encode_headers(\$headers) if ($self->target > 1.1);

        while (my ($key, $value) = each(%{$headers})) {

            if (defined($value)) {

                $frame .= lc($key) . ': ' . $value . $self->eol();

            }

        }

    } else {

        $frame .= $self->eol();

    }

    $frame .= $self->eol();
    $frame .= $body;
    $frame .= EOF;

    return $frame;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);
    
    $headers = $self->headers || {};
    $self->{eol} = ($self->target > 1.1) ? CRLF : LF;

    $self->_decode_headers(\$headers) if ($self->target > 1.1);
    $self->{header} = XAS::Lib::Stomp::Frame::Headers->new($headers);

    return $self;

}

sub _encode_headers {
    my $self    = shift;
    my $headers = shift; # a pointer to a reference of a hash, oh my...

    my $ENCODE_KEYS = '['.join('', map(sprintf('\\x%02x', ord($_)), keys(%ENCODE_MAP))).']';

    while (my ($k, $v) = each(%$$headers)) {

        $k = encode('utf8', $k);
        $v = encode('utf8', $v);

        $v =~ s/($ENCODE_KEYS)/$ENCODE_MAP{$1}/ego;
        $k =~ s/($ENCODE_KEYS)/$ENCODE_MAP{$1}/ego;

        $$headers->{$k} = $v;

    }

}

sub _decode_headers {
    my $self    = shift;
    my $headers = shift; # a pointer to a reference of a hash, oh my...

    while (my ($k, $v) = each(%$$headers)) {

        $k = decode('utf8', $k);
        $v = decode('utf8', $v);

        if ($v =~ m/(\\.)/) {

            unless ($v =~ s/(\\.)/$DECODE_MAP{$1}/eg) {

                $self->throw_msg(
                    'xas.lib.stomp.frame.decode_header',
                    'badval',
                );

            }

        }

        if ($k =~ m/(\\.)/) {

            unless ($k =~ s/(\\.)/$DECODE_MAP{$1}/eg) {

                $self->throw_msg(
                    'xas.lib.stomp.frame.decode_header',
                    'badkey'
                );

            }

        }

        $$headers->{$k} = $v;

    }

}

package # hide from cpan...
      XAS::Lib::Stomp::Frame::Headers;

our $VERSION = '0.01';

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base',
  constants => 'REFS',
;

#use Data::Dumper;

sub remove {
    my ($self, $key) = @_;

    my @x = grep { $_ ne $key } @{$self->{_methods}};
    $self->{_methods} = \@x;

    delete($self->{$key});

    no warnings;
    no strict REFS;

    *$key = undef;

}

sub add {
    my ($self, $key, $value) = @_;

    $key =~ s/-/_/g;

    $self->{$key} = $value;
    push(@{$self->{_methods}}, $key);

    no warnings;
    no strict REFS;

    *$key = sub {
        my $self = shift;
        $self->{$key} = shift if @_;
        return $self->{$key};
    };

}

sub introspect {
    my $self = shift;

    return $self->{_methods};

}

sub devolve {
    my $self = shift;

    my $value;
    my $header = {};

    foreach my $key (@{$self->{_methods}}) {

        $value = $self->{$key};
        $key =~ s/_/-/g;
        $header->{$key} = $value;

    }

    return $header;

}

sub init {
    my $self    = shift;
    my $configs = shift;

    $self->{config}   = $configs;
	$self->{_methods} = undef;

    # turn frame headers into mutators of there values

    while (my ($key, $value) = each(%$configs)) {

        $key =~ s/-/_/g;

        $self->{$key} = $value;
        push(@{$self->{_methods}}, $key);

        no warnings;
        no strict REFS;

        *$key = sub {
            my $self = shift;
            $self->{$key} = shift if @_;
            return $self->{$key};
        };

    }

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Stomp::Frame - A STOMP Frame

=head1 SYNOPSIS

  use XAS::Lib::Stomp::Frame;

  my $frame = XAS::Lib::Stomp::Frame->new(
    -target  => '1.0',
    -command => $command,
    -headers => $headers,
    -body    => $body,
  );

  ... or ...

  my $frame = XAS:::Lib::Stomp::Frame->new();

  $frame->target('1.0');
  $frame->command('MESSAGE');
  $frame->header->add('destination', '/queue/foo');
  $frame->body('this is the body');

  ... stringification ...

  my $string = $frame->as_string;

=head1 DESCRIPTION

This module encapsulates a STOMP frame. STOMP is the Streaming Text
Orientated Messaging Protocol (or the Protocol Briefly Known as TTMP
and Represented by the symbol :ttmp). It's a simple and easy to
implement protocol for working with Message Orientated Middleware from
any language. 

A STOMP frame consists of a command, a series of headers and a body.

=head1 METHODS

=head2 new

Create a new XAS::Lib::Stomp::Frame object:

  my $frame = XAS::Lib::Stomp::Frame->new(
    -command => $command,
    -headers => $headers,
    -body    => $body,
  );

It can take the following parameters:

=over 4

=item B<-target>

Specify a STOMP protocol version number. It currently supports 1.0,
1.1 and 1.2, defaulting to 1.0.

=item B<-command>

The command verb.

=item B<-headers>

Headers for this command. This supports the 'bytes_message' header which
indicates a binary body.

=item B<-body>

A body for the command.

=back

=head2 as_string

Create a buffer from the serialized frame.

  my $buffer = $frame->as_string;

=head2 header

This returns a XAS::Lib::Stomp::Frame::Headers object. This object contains
auto generated mutators of the header fields in a STOMP frame. 

=head1 MUTATORS

=head2 command

This get/sets STOMP frames command verb.

=head2 body

This get/sets the body of the STOMP frame.

=head1 XAS::Lib::Stomp::Frame::Headers

This is an internal class that auto generates mutators for the headers in a 
STOMP frame. Any dashes in the header names are converted to underscores 
for the mutators name.

Example, a header of:

 content-type: test/plain

Will become the mutator content_type().

The usual way to access the headers is as follows:

 my $type = $frame->header->content_type;

 $frame->header->content_type('text/plain');

The following methods are also available.

=head2 devolve

This will create a hash with header/value pairs. Any underscores are 
converted to dashes in the headers name. Primarily used during
stringification of the STOMP frame.

=head2 introspect

This will return a list of headers.

=head2 add($name, $value)

This will add a header.

=over 4

=item B<$name>

The name of the header.

=item B<$value>

The value for the header.

=back

=head2 remove($name)

This will remove a header.

=over 4

=item B<$name>

The name of the header to remove.

=back

=head1 ACKNOWLEDGEMENTS

This module is based on L<Net::Stomp::Frame|https://metacpan.org/pod/Net::Stomp::Frame> by Leon Brocard <acme@astray.com>.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

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
