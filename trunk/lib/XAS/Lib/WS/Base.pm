package XAS::Lib::WS::Base;

our $VERSION = '0.01';

use HTTP::Response;
use WWW::Curl::Easy;

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base',
  accessors => 'curl',
  mutators  => 'retcode',
  utils     => 'dotid',
  vars => {
    PARAMS => {
      -headers         => { optional => 1, default => 0 },
      -keep_alive      => { optional => 1, default => 0 },
      -followlocation  => { optional => 1, default => 1 },
      -max_redirects   => { optional => 1, default => 3 },
      -ssl_verify_peer => { optional => 1, default => 1 },
      -ssl_verify_host => { optional => 1, default => 1 },
      -timeout         => { optional => 1, default => 30 },
      -connect_timeout => { optional => 1, default => 300 },
      -ssl_cacert      => { optional => 1, default => undef },
      -ssl_keypasswd   => { optional => 1, default => undef },
      -proxy_url       => { optional => 1, default => undef },
      -ssl_cert        => { optional => 1, default => undef, depends => [ 'ssl_key' ] },
      -ssl_key         => { optional => 1, default => undef, depends => [ 'ssl_cert' ] },
      -password        => { optional => 1, default => undef, depends => [ 'username' ] },
      -username        => { optional => 1, default => undef, depends => [ 'password' ] },
      -proxy_password  => { optional => 1, default => undef, depends => [ 'proxy_username' ] },
      -proxy_username  => { optional => 1, default => undef, depends => [ 'proxy_password' ] },
      -auth_method     => { optional => 1, default => 'noauth', regex => qr/any|noauth|basic|digest|ntlm|negotiate/ },
      -proxy_auth      => { optional => 1, default => 'noauth', regex => qr/any|noauth|basic|digest|ntlm|negotiate/ },
    }
  },
  messages => {
    curl => 'curl error: %s, reason: %s',
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub request {
    my $self = shift;
    my ($request) = validate_pos(@_,
        { isa => 'HTTP::Request' }
    );

    my $header_ref;
    my $content_ref;
    my $response = undef;
    my $header   = $request->headers->as_string("\n");
    my @headers  = split("\n", $header);

    push(@headers, "Connection: close") unless $self->keep_alive;

    $self->curl->setopt(CURLOPT_URL,        $request->uri);
    $self->curl->setopt(CURLOPT_HTTPHEADER, \@headers) if (scalar(@headers));

    # I/O for the request

    $self->curl->setopt(CURLOPT_WRITEDATA,     \$content_ref);
    $self->curl->setopt(CURLOPT_HEADERDATA,    \$header_ref);
    $self->curl->setopt(CURLOPT_READFUNCTION,  \&_read_callback);
    $self->curl->setopt(CURLOPT_WRITEFUNCTION, \&_chunk_callback);

    # other options depending on request type

    if ($request->method eq 'GET') {

        $self->curl->setopt(CURLOPT_HTTPGET, 1);

    } elsif ($request->method eq 'POST') {

        use bytes;

        my $content = $request->content;

        $self->curl->setopt(CURLOPT_POST,           1);
        $self->curl->setopt(CURLOPT_POSTFIELDSIZE,  length($content));
        $self->curl->setopt(CURLOPT_COPYPOSTFIELDS, $content);

    } elsif ($request->method eq 'PUT') {

        use bytes;

        my $content = $request->content;

        $self->curl->setopt(CURLOPT_UPLOAD,     1);
        $self->curl->setopt(CURLOPT_READDATA,   \$content);
        $self->curl->setopt(CURLOPT_INFILESIZE, length($content));

    } elsif ($request->method eq 'HEAD') {

        $self->curl->setopt(CURLOPT_NOBODY, 1);

    } else {

        $self->curl->setopt(CURLOPT_CUSTOMREQUEST, uc $request->method);

    }

    # perform the request and create the response

   if (($self->{retcode} = $self->curl->perform) == 0) {

        my $message;
        my @headers = split("\r\n\r\n", $header_ref);

        $response = HTTP::Response->parse($headers[-1]);
        $response->content($content_ref);

        $message = $response->message;
        $response->message($message) if ($message =~ s/\r//g);

    } else {

        $self->throw_msg(
            dotid($self->class) . '.request.curl',
            'curl',
            $self->retcode, lc($self->curl->strerror($self->retcode))
        );

    }

    return $response;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _read_callback {
    my ( $maxlength, $pointer ) = @_;

    my $data = substr( $$pointer, 0, $maxlength );

    $$pointer =
      length($$pointer) > $maxlength
      ? scalar substr( $$pointer, $maxlength )
      : '';

    return $data;

}

sub _chunk_callback {
    my ( $data, $pointer ) = @_;

    ${$pointer} .= $data;

    return length($data);

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    my $authen          = 0;
    my $timeout         = $self->timeout * 1000;
    my $protocols       = (CURLPROTO_HTTP & CURLPROTO_HTTPS);
    my $connect_timeout = $self->timeout * 1000;

    $self->{curl} = WWW::Curl::Easy->new();

    # basic options

    $self->curl->setopt(CURLOPT_HEADER,            $self->headers);
    $self->curl->setopt(CURLOPT_VERBOSE,           $self->xdebug);
    $self->curl->setopt(CURLOPT_MAXREDIRS,         $self->max_redirects);
    $self->curl->setopt(CURLOPT_PROTOCOLS,         $protocols);
    $self->curl->setopt(CURLOPT_NOPROGRESS,        1);
    $self->curl->setopt(CURLOPT_TIMEOUT_MS,        $timeout);
    $self->curl->setopt(CURLOPT_FORBID_REUSE,      !$self->keep_alive);
    $self->curl->setopt(CURLOPT_FOLLOWLOCATION,    $self->followlocation);
    $self->curl->setopt(CURLOPT_CONNECTTIMEOUT_MS, $connect_timeout);

    # setup authentication

    $authen = CURLAUTH_ANY          if ($self->auth_method eq 'any');
    $authen = CURLAUTH_NTLM         if ($self->auth_method eq 'ntlm');
    $authen = CURLAUTH_BASIC        if ($self->auth_method eq 'basic');
    $authen = CURLAUTH_DIGEST       if ($self->auth_method eq 'digest');
    $authen = CURLAUTH_GSSNEGOTIATE if ($self->auth_method eq 'negotitate');

    $self->curl->setopt(CURLOPT_HTTPAUTH, $authen);

    if ($self->username) {

        $self->curl->setopt(CURLOPT_USERNAME, $self->username);
        $self->curl->setopt(CURLOPT_PASSWORD, $self->password);

    }

    # setup proxy stuff

    if ($self->proxy_url) {

        $authen = 0;

        $authen = CURLAUTH_ANY          if ($self->proxy_auth eq 'any');
        $authen = CURLAUTH_NTLM         if ($self->proxy_auth eq 'ntlm');
        $authen = CURLAUTH_BASIC        if ($self->proxy_auth eq 'basic');
        $authen = CURLAUTH_DIGEST       if ($self->proxy_auth eq 'digest');
        $authen = CURLAUTH_GSSNEGOTIATE if ($self->proxy_auth eq 'negotitate');

        $self->curl->setopt(CURLOPT_PROXY,         $self->proxy_url);
        $self->curl->setopt(CURLOPT_PROXYAUTH,     $authen);
        $self->curl->setopt(CURLOPT_PROXYUSERNAME, $self->proxy_username);
        $self->curl->setopt(CURLOPT_PROXYPASSWORD, $self->proxy_password);

    }

    # set up the SSL stuff

    $self->curl->setopt(CURLOPT_SSL_VERIFYPEER, $self->ssl_verify_peer);
    $self->curl->setopt(CURLOPT_SSL_VERIFYHOST, $self->ssl_verify_host);

    if ($self->ssl_keypasswd) {

        $self->curl->setop(CURLOPT_KEYPASSWD, $self->ssl_keypasswd);

    }

    if ($self->ssl_cacert) {

        $self->curl->setopt(CURLOPT_CAINFO, $self->ssl_cacert);

    }

    if ($self->ssl_cert) {

        $self->curl->setopt(CURLOPT_SSLCERT, $self->ssl_cert);
        $self->curl->setopt(CURLOPT_SSLKEY,  $self->ssl_key);

    }

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::WS::Base - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Lib::WS::Base;

=head1 DESCRIPTION

=head1 METHODS

=head2 method1

=head1 SEE ALSO

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See L<http://dev.perl.org/licenses/> for more information.

=cut
