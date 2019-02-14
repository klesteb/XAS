package XAS::Lib::Curl::HTTP;

our $VERSION = '0.02';

BEGIN {
    no warnings 'redefine';

    use WWW::Curl::Easy;

    eval {

        # these constants are not always defined for libcurl on RHEL 5,6,7.
        # but they are, if you compile libcurl on Windows

        unless (CURLAUTH_ONLY) {

            sub CURLAUTH_ONLY { (1 << 31); } # defined in curl.h

        }

    };

}

use Data::Dumper;
use HTTP::Response;
use Try::Tiny::Retry ':all';

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base',
  accessors => 'curl',
  import    => 'class',
  mutators  => 'retcode',
  utils     => ':validation dotid trim',
  vars => {
    PARAMS => {
      -headers         => { optional => 1, default => 0 },
      -keep_alive      => { optional => 1, default => 0 },
      -fail_on_error   => { optional => 1, default => 0 },
      -followlocation  => { optional => 1, default => 1 },
      -ssl_verify_peer => { optional => 1, default => 1 },
      -ssl_verify_host => { optional => 1, default => 1 },
      -max_redirects   => { optional => 1, default => 3 },
      -connect_retries => { optional => 1, default => 5 },
      -timeout         => { optional => 1, default => 30 },
      -connect_timeout => { optional => 1, default => 300 },
      -ssl_cacert      => { optional => 1, default => undef },
      -ssl_keypasswd   => { optional => 1, default => undef },
      -proxy_url       => { optional => 1, default => undef },
      -ssl_cert        => { optional => 1, default => undef, depends => [ '-ssl_key' ] },
      -ssl_key         => { optional => 1, default => undef, depends => [ '-ssl_cert' ] },
      -password        => { optional => 1, default => undef, depends => [ '-username' ] },
      -username        => { optional => 1, default => undef, depends => [ '-password' ] },
      -proxy_password  => { optional => 1, default => undef, depends => [ '-proxy_username' ] },
      -proxy_username  => { optional => 1, default => undef, depends => [ '-proxy_password' ] },
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
    my ($request) = validate_params(\@_, [
        { isa => 'HTTP::Request' }
    ]);

    my @head;
    my @buffer;
    my $response = undef;
    my $header   = $request->headers->as_string("\n");
    my @headers  = split("\n", $header);

    push(@headers, "Connection: close") unless $self->keep_alive;

    $self->curl->setopt(CURLOPT_URL,        $request->uri);
    $self->curl->setopt(CURLOPT_HTTPHEADER, \@headers) if (scalar(@headers));

    # I/O for the request

    $self->curl->setopt(CURLOPT_WRITEDATA,      \@buffer);
    $self->curl->setopt(CURLOPT_HEADERDATA,     \@buffer);
    $self->curl->setopt(CURLOPT_READFUNCTION,   \&_read_callback);
    $self->curl->setopt(CURLOPT_WRITEFUNCTION,  \&_write_callback);
    $self->curl->setopt(CURLOPT_HEADERFUNCTION, \&_write_callback);

    # other options depending on request type

    if ($request->method eq 'GET') {

        $self->curl->setopt(CURLOPT_HTTPGET, 1);

    } elsif ($request->method eq 'POST') {

        use bytes;

        my $content = $request->content;

        $self->curl->setopt(CURLOPT_POST,          1);
        $self->curl->setopt(CURLOPT_POSTFIELDSIZE, length($content));
        $self->curl->setopt(CURLOPT_POSTFIELDS,    $content);

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

    retry {
        
        # perform the request and create the response

        if (($self->{'retcode'} = $self->curl->perform) == 0) {

            my @temp;
            my $message;
            my $content;

            print Dumper(@buffer) if ($self->xdebug);

            # there may be multiple responses within the buffer, we only
            # want the last one. so search backwards until a HTTP header
            # is found.

            while (my $line = pop(@buffer)) {

                push(@temp, $line);
                last if ($line =~ /^HTTP\//);

            }

            $content = join('', reverse(@temp));
            $response = HTTP::Response->parse($content);
            $response->request($request);

        } else {

            $self->throw_msg(
                dotid($self->class) . '.request.curl',
                'curl',
                $self->retcode, lc($self->curl->strerror($self->retcode))
            );

        }
        
    } retry_if {
        
        my $ex = $_;
        my $stat = 1;
        
        if (($self->retcode != 5) && # CURLE_COULDNT_RESOLVE_PROXY 
            ($self->retcode != 6) && # CURLE_COULDNT_RESOLVE_HOST
            ($self->retcode != 7)) { # CURLE_COULDNT_CONNECT
                
            $stat = 0;
                
        }
        
        $stat;
        
    } delay {
        
        my $attempts = shift;

        return if ($attempts > $self->connect_retries);
        sleep int(rand($self->timeout));

    } catch {
        
        my $ex = $_;
        
        die $ex;
        
    };

    return $response;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _read_callback {
    my ($maxlength, $pointer) = @_;

    my $data = substr($$pointer, 0, $maxlength);

    $$pointer =
      length($$pointer) > $maxlength
      ? scalar substr($$pointer, $maxlength)
      : '';

    return $data;

}

sub _write_callback {
    my ($data, $pointer) = @_;

    push(@{$pointer}, $data);

    return length($data);

}

sub _define_authentication {
    my $self = shift;

    my $authen = 0;

    $authen = CURLAUTH_ANY                          if ($self->auth_method eq 'any');
    $authen = CURLAUTH_NTLM         | CURLAUTH_ONLY if ($self->auth_method eq 'ntlm');
    $authen = CURLAUTH_BASIC        | CURLAUTH_ONLY if ($self->auth_method eq 'basic');
    $authen = CURLAUTH_DIGEST       | CURLAUTH_ONLY if ($self->auth_method eq 'digest');
    $authen = CURLAUTH_GSSNEGOTIATE | CURLAUTH_ONLY if ($self->auth_method eq 'negotiate');

    return $authen;

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    my $authen          = 0;
    my $timeout         = $self->timeout * 1000;
    my $protocols       = (CURLPROTO_HTTP & CURLPROTO_HTTPS);
    my $connect_timeout = $self->timeout * 1000;

    $self->{'curl'} = WWW::Curl::Easy->new();

    # basic options

    $self->curl->setopt(CURLOPT_HEADER,            $self->headers);
    $self->curl->setopt(CURLOPT_VERBOSE,           $self->xdebug);
    $self->curl->setopt(CURLOPT_MAXREDIRS,         $self->max_redirects);
    $self->curl->setopt(CURLOPT_PROTOCOLS,         $protocols);
    $self->curl->setopt(CURLOPT_NOPROGRESS,        1);
    $self->curl->setopt(CURLOPT_TIMEOUT_MS,        $timeout);
    $self->curl->setopt(CURLOPT_FAILONERROR,       $self->fail_on_error);
    $self->curl->setopt(CURLOPT_FORBID_REUSE,      !$self->keep_alive);
    $self->curl->setopt(CURLOPT_FOLLOWLOCATION,    $self->followlocation);
    $self->curl->setopt(CURLOPT_CONNECTTIMEOUT_MS, $connect_timeout);

    # setup authentication

    $authen = $self->_define_authentication();

    $self->curl->setopt(CURLOPT_HTTPAUTH, $authen);

    if ($self->username) {

        $self->curl->setopt(CURLOPT_USERNAME, $self->username);
        $self->curl->setopt(CURLOPT_PASSWORD, $self->password);

    }

    # setup proxy stuff

    if ($self->proxy_url) {

        # setup proxy authentication

        $authen = $self->_define_authentication();

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

XAS::Lib::Curl::HTTP - A class for the XAS environment

=head1 SYNOPSIS

 use HTTP::Request;
 use XAS::Lib::Curl::HTTP;

 my $response;
 my $request = HTTP::Request->new(GET => 'http://scm.kesteb.us/trac');
 my $ua = XAS::Lib::Curl::HTTP->new();

 $response = $ua->request($request);

 print $response->content;

=head1 DESCRIPTION

This module uses L<libcurl|http://curl.haxx.se/libcurl/> as the HTTP engine
to make requests from a web server. 

=head1 METHODS

All true/false values use 0/1 as the indicator.

=head2 new

This method initializes the module and takes the following parameters:

=over 4

=item B<-keep_alive>

A toggle to tell curl to forbid the reuse of sockets, defaults to true.

=item B<-follow_location>

A toggle to tell curl to follow redirects, defaults to true.

=item B<-max_redirects>

The number of redirects to follow, defaults to 3.

=item B<-timeout>

The timeout for the connection, defaults to 60 seconds.

=item B<-connect_timeout>

The timeout for the initial connection, defaults to 300 seconds.

=item B<-connect_retries>

The number of retries to attempt a connection, defaults to 5.

=item B<-auth_method>

The authentication method to use, defaults to 'noauth'. Possible
values are 'any', 'basic', 'digest', 'ntlm', 'negotiate'. If a username
and password are supplied, curl defaults to 'basic'.

=item B<-password>

An optional password to use, implies a username. Wither the password is
actually used, depends on -auth_method.

=item B<-username>

An optional username to use, implies a password.

=item B<-ssl_cacert>

An optional CA cerificate to use.

=item B<-ssl_keypasswd>

An optional password for a signed cerificate.

=item B<-ssl_cert>

An optional certificate to use.

=item B<-ssl_key>

An optional key for a certificate to use.

=item B<-ssl_verify_host>

Wither to verify the host certifcate, defaults to true.

=item B<-ssl_verify_peer>

Wither to verify the peer certificate, defaults to true.

=item B<-proxy_url>

The url of a proxy that needs to be transversed.

=item B<-proxy_auth>

The authentication method to use, defaults to 'noauth'. Possible
values are 'any', 'basic', 'digest', 'ntlm', 'negotiate'. If a proxy
username and a proxy password are supplied, curl defaults to 'basic'.

=item B<-proxy_password>

An optional password to use, implies a username. Wither the password is
actually used, depends on -proxy_auth.

=item B<-proxy_username>

An optional username to use, implies a password.

=back

=head2 request($request)

This method sends the requset to the web server. The request will return
a L<HTTP::Response|https://metacpan.org/pod/HTTP::Response> object. It takes the following parameters:

=over 4

=item B<$request>

A L<HTTP::Request|https://metacpan.org/pod/HTTP::Request> object.

=back

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=item L<WWW::Curl|https://metacpan.org/pod/WWW::Curl>

=item L<libcurl|http://curl.haxx.se/libcurl/>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2017 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text

=cut
