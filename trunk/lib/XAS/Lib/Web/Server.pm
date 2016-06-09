package XAS::Lib::Web::Server;

our $VERSION = '0.01';

use POE;
use Plack::Util;
use POE::Filter::HTTPD;
use HTTP::Message::PSGI;
use XAS::Constants 'CODEREF';

use XAS::Class
  version => $VERSION,
  base    => 'XAS::Lib::Net::Server',
  vars => {
    PARAMS => {
      -app => { type => CODEREF }
    }
  }
;

#use Data::Dumper;

# ---------------------------------------------------------------------
# Public Events
# ---------------------------------------------------------------------

sub process_request {
    my ($self, $request, $ctx) = @_[OBJECT,ARG0,ARG1];

    my $alias    = $self->alias;
    my $version  = $request->header('X-HTTP-Verstion') || '0.9';
    my $protocol = "HTTP/$version";

    my $env = req_to_psgi($request,
       SERVER_NAME        => $self->address,
       SERVER_PORT        => $self->port,
       SERVER_PROTOCOL    => $protocol,
       'psgi.streaming'   => Plack::Util::TRUE,
       'psgi.nonblocking' => Plack::Util::TRUE,
       'psgi.runonce'     => Plack::Util::FALSE,
    );

    my $r = Plack::Util::run_app($self->app, $env);
    my $response = res_from_psgi($r);

    $poe_kernel->post($alias, 'process_response', $response, $ctx);

}

# ---------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# Private Events
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{'filter'} = POE::Filter::HTTPD->new();

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Web::Server - A simple web server for micro services.

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

This class provides a simple web server that is suitable for embedding into a 
micro service application. It inherits from L<XAS::Lib::Net::Server|XAS::Lib::Net::Server>.
This was written to allow L<Web::Machine|https://metacpan.org/pod/Web::Machine> 
to interact with a POE based environent. 

=head1 METHODS

=head2 new

An additional parameter was added to define the PSGI based application to run.

=over 4

=item B<-app>

This should be a complied PSGI based application. Please refer to the above
example.

=back

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
