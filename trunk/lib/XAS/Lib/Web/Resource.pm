package XAS::Lib::Web::Resource;

use strict;
use warnings;

use Net::LDAP;
use XAS::Factory;
use Data::Dumper;
use Hash::MultiValue;
use parent 'Web::Machine::Resource';
use Web::Machine::Util 'create_header';

# -------------------------------------------------------------------------
# Web::Machine::Resource methods
# ------------------------------------------------------------------------

sub init {
    my $self = shift;
    my $args = shift;

    $self->{'template'} = exists $args->{'template'}
      ? $args->{'template'}
      : undef;

    $self->{'json'} = exists $args->{'json'}
      ? $args->{'json'}
      : undef;

    $self->{'schema'} = exists $args->{'schema'}
      ? $args->{'schema'}
      : undef;

    $self->{'app_name'} = exists $args->{'app_name'}
      ? $args->{'app_name'}
      : 'Test App';

    $self->{'app_description'} = exists $args->{'app_description'}
      ? $args->{'app_description'}
      : 'Testing Testing 1 2 3';

    $self->{'log'} = XAS::Factory->module('logger');
    $self->{'env'} = XAS::Factory->module('environment');

    $self->errcode(0);
    $self->errstr('');

}

sub is_authorized {
    my $self = shift;
    my $auth = shift;

    my $stat      = 0;
    my $domain    = '';
    my $dc_server = '';

    # a simple algorithm, connect to AD and provide a username
    # and password. if there is no error, they are authenticated.

    if ($auth) {

        my $username = $auth->username;
        my $password = $auth->password;
        my $aduser   = sprintf("%s\@%s", $username, $domain);

        my $ad = Net::LDAP->new($dc_server) or die $@;
        my $rc = $ad->bind($aduser, password => $password);

        $stat = 1 unless ($rc->is_error);
        $ad->unbind();

        return $stat;

    }

    return create_header('WWWAuthenticate' => [ 'Basic' => ( realm => 'XAS Rest' ) ] );

}

sub options {
    my $self = shift;

    my $options;
    my @accepted;
    my @provided;
    my $allowed = $self->allowed_methods;

    foreach my $hash (@{$self->content_types_accepted}) {

        my ($key) = keys %$hash;
        push(@accepted, $key);

    }

    foreach my $hash (@{$self->content_types_provided}) {

        my ($key) = keys %$hash;
        push(@provided, $key);

    }

    $options->{'allow'}    = join(',', @$allowed);
    $options->{'accepted'} = join(',', @accepted);
    $options->{'provides'} = join(',', @provided);

    return $options;

}

sub allowed_methods { [qw[ OPTIONS GET HEAD ]] }

sub content_types_provided {

    return [
        { 'text/html'            => 'to_html' },
        { 'application/hal+json' => 'to_json' },
    ];

}

sub charset_provided { return ['UTF-8']; }

sub finish_request {
    my $self     = shift;
    my $metadata = shift;

    my $data;
    my $output;
    my $uri    = $self->request->uri;
    my $status = $self->errcode || 403;
    my $type   = $metadata->{'Content-Type'};

    if (defined($metadata->{'exception'})) {

        my $ref    = ref($metadata->{'exception'});
        my $ex     = $metadata->{'exception'};
        my $format = ($type->subject =~ /json/) ? 'json' : 'html';

        $data->{'_links'}     = $self->get_links();
        $data->{'navigation'} = $self->get_navigation();

        if (($ref eq 'XAS::Exception') or ($ref eq 'Badger::Exception')) {

            $data->{'_embedded'}->{'errors'} = [{
                title  => $self->errstr,
                status => $status,
                code   => $ex->type,
                detail => $ex->info
            }];

        } else {

            $data->{'_embedded'}->{'errors'} = [{
                title  => $self->errstr,
                status => $status,
                code   => 'unknown error',
                detail => sprintf('%s', $ex)
            }];

        }

        if ($format eq 'json') {

            $output = $self->format_json($data);
            $self->response->content_type('application/hal+json');

        } else {

            $output = $self->format_html($data);

        }

        $self->response->body($output);
        $self->response->header('Location' => $uri->path);
        $self->response->status($status);

        {
            use bytes;
            $self->response->header('Content-Length' => length($output));
        }

    }

}

# -------------------------------------------------------------------------
# Our methods
# ------------------------------------------------------------------------

sub process_exception {
    my $self   = shift;
    my $title  = shift;
    my $status = shift;

    $self->{'errcode'} = $$status;
    $self->{'errstr'}  = $title;

}

# -------------------------------------------------------------------------
# accessors
# -------------------------------------------------------------------------

sub env {
    my $self = shift;

    return $self->{'env'};

}

sub log {
    my $self = shift;

    return $self->{'log'};

}
      
sub schema {
    my $self = shift;

    return $self->{'schema'};

}

sub app_name {
    my $self = shift;

    return $self->{'app_name'};

}

sub app_description {
    my $self = shift;

    return $self->{'app_description'};

}

sub json {
    my $self = shift;

    return $self->{'json'};

}

sub errcode {
    my $self = shift;
    my $code = shift;

    $self->{'errcode'} = $code if (defined($code));

    return $self->{'errcode'};

}

sub errstr {
    my $self   = shift;
    my $string = shift;

    $self->{'errstr'} = $string if (defined($string));

    return $self->{'errstr'};

}

sub template {
    my $self = shift;

    return $self->{'template'};

}

# -------------------------------------------------------------------------
# methods
# -------------------------------------------------------------------------

sub get_navigation {
    my $self = shift;

    return [{
        link => '/',
        text => 'Root'
    }];

}

sub get_links {
    my $self = shift;

    return {
        self => {
            title => 'Root',
            href  => '/',
        },
    };

}

sub get_response {
    my $self = shift;

    my $data;

    $data->{'_links'}     = $self->get_links();
    $data->{'navigation'} = $self->get_navigation();

    return $data;

}

sub json_to_multivalue {
    my $self = shift;
    my $json = shift;

    my $decoded = $self->json->decode($json);
    my $params  = Hash::MultiValue->new();

    while (my ($key, $value) = each(%$decoded)) {

        $params->add($key, $value);

    }

    return $params;

}

sub to_json {
    my $self = shift;

    my $data = $self->get_response();
    my $json = $self->format_json($data);

    return $json;

}

sub to_html {
    my $self = shift;

    my $data = $self->get_response();
    my $html = $self->format_html($data);

    return $html;

}

sub format_json {
    my $self = shift;
    my $data = shift;

    delete $data->{'navigation'};

    return $self->json->encode($data);

}

sub format_html {
    my $self = shift;
    my $data = shift;

    my $html;
    my $view = {
        view => {
            title       => $self->app_name,
            description => $self->app_description,
            template    => 'dispatcher.tt',
            data        => $data,
        }
    };

    $self->template->process('wrapper.tt', $view, \$html);

    return $html;

}

1;

__END__

=head1 NAME

XAS::Lib::Web::Resource - A class to provide a Web Machine resource

=head1 SYNOPSIS

 package WebService;

 use Template;
 use JSON::XS;
 use Web::Machine;
 use Plack::Builder;
 use Plack::App::File;
 use XAS::Lib::Web::Server
 use XAS::Lib::Web::Resource;

 use WPM::Class
   version   => '0.01',
   base      => 'WPM::Lib::App::Service',
   mixin     => 'WPM::Lib::Mixin::Configs',
   accessors => 'cfg',
   vars => {
     SERVICE_NAME         => 'WEB_SERVICE',
     SERVICE_DISPLAY_NAME => 'Basic Web Service',
     SERVICE_DESCRIPTION  => 'A basic web service',
   }
 ;

 sub build_app {
     my $self = shift;
 
     my $base = '/home/kevin/dev/web';

     my $config = {
         INCLUDE_PATH => $base . '/root',   # or list ref
         INTERPOLATE  => 1,          # expand "$var" in plain text
         POST_CHOMP   => 1,          # cleanup whitespace
     };

     # define app name and description

     my $name = 'WEB Services';
     my $description = 'A test api using RESTFUL HAL';

     # create our various objects

     my $template = Template->new($config);
     my $json     = JSON::XS->new->pretty->utf8();

     # allow underlines "_" to preceed variable names.

     $Template::Stash::PRIVATE = undef;

     # fire up the builder

     my $builder = Plack::Builder->new();

     # handlers, using Plack's default URLMap for routing

     $builder->mount('/' => Web::Machine->new(
         resource => 'XAS::Lib::Web::Resource',
         resource_args => [
             template        => $template,
             json            => $json,
             app_name        => $name,
             app_description => $description
         ] )->to_app
     );

     # static files

     $builder->mount('/js' => Plack::App::File->new(
         root => $base . '/root/js' )->to_app
     );

     $builder->mount('/css' => Plack::App::File->new(
         root => $base . '/root/css')->to_app
     );

     $builder->mount('/yaml' => Plack::App::File->new(
         root => $base . '/root/yaml/yaml')->to_app
     );

     return $builder->to_app;

 }

 sub setup {
    my $self = shift;

    my $alias = 'rexecd';

    $self->load_config();

    my $controller = XAS::Lib::Web::Server->new(
        -alias    => $alias,
        -port     => $self->cfg->val('system', 'port', 9507),
        -address  => $self->cfg->val('system', 'address', 'localhost'),
        -app      => $self->build_app(),
    );

    $self->service->register($alias);

 }

 sub main {
     my $self = shift;

     $self->log->info_msg('startup');

     $self->setup();
     $self->service->run();

     $self->log->info_msg('shutdown');

 }

 package main;

 my $ws = WebService->new();
 $ws->run;

=head1 DESCRIPTION

This class uses L<Web::Machine|https://> as a base class to provide a REST
based web service. 

=head1 METHODS

=head2 method1

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
