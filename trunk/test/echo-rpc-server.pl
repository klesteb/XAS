use lib '../lib';

package Echo;

 use POE;
 use XAS::Class
   debug   => 0,
   version => '0.01',
   base    => 'XAS::Lib::Net::Server',
   mixin   => 'XAS::Lib::Mixins::JSON::Server XAS::Lib::Mixins::Keepalive',
   vars => {
     PARAMS => {
       -port          => { optional => 1, default => 9500 },
       -tcp_keepalive => { optional => 1, default => 0 }
     }
   }
 ;

 sub handle_connection {
     my ($self, $wheel) = @_[OBJECT, ARG0];

     if (my $socket = $self->{clients}->{$wheel}->{socket}) {

         $self->enable_keepalive($socket) if ($self->tcp_keepalive);

     }

 }

 sub echo {
     my ($self, $params, $ctx) = @_[OBJECT, ARG0, ARG1];

     my $alias = $self->alias;
     my $line  = $params->{line};

     $poe_kernel->post($alias, 'process_response', $line, $ctx);

 }

 sub init {
     my $class = shift;

     my $self = $class->SUPER::init(@_);
     my $methods = ['echo'];

     $self->init_json_server($methods);
     $self->init_keepalive() if ($self->tcp_keepalive);

     return $self;

 }

 package main;

     my $echo = Echo->new();

     $echo->run();
