use lib '../lib';

package Test1;

use POE;
use XAS::Lib::POE::PubSub;
use XAS::Class
  debug     => 0,
  version   => '0.01',
  base      => 'XAS::Lib::POE::Service',
  accessors => 'events',
  vars => {
    PARAMS => {
      -alias => { optional => 1, default => 'test1' }
    }
  }
;

use Data::Dumper;

sub session_initialize {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: session_initialize");

    $poe_kernel->state('testing', $self);

    $self->SUPER::session_initialize();

}

sub session_startup {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: session_startup");

    $self->events->subscribe($alias);

    $self->SUPER::session_startup();

}

sub session_idle {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: session_idle");

    $self->events->publish(
        -event => 'testing', 
        -args  => ['test1', 'test1']
    );

    $self->SUPER::session_idle();
    
}

sub testing {
    my ($self, $args) = @_[OBJECT, ARG0];

    my $alias = $self->alias;

    $self->log->debug("$alias: testing()");

    warn Dumper($args);

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{events} = XAS::Lib::POE::PubSub->new();

    return $self;

}

package Test2;

use POE;
use XAS::Lib::POE::PubSub;
use XAS::Class
  debug     => 0,
  version   => '0.01',
  base      => 'XAS::Lib::POE::Service',
  accessors => 'events',
  vars => {
    PARAMS => {
      -alias => { optional => 1, default => 'test2' }
    }
  }
;

use Data::Dumper;

sub session_initialize {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: session_initialize");

    $self->events->subscribe($alias, 'system');

    $poe_kernel->state('testing', $self);

    $self->SUPER::session_initialize();

}

sub session_idle {
    my $self = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: runner");

    $self->events->publish(
        -event   => 'testing', 
        -channel => 'system',
        -args    => ['test2', 'test2']
    );

    $self->SUPER::session_idle();
    
}

sub testing {
    my ($self, $args) = @_[OBJECT, ARG0];

    my $alias = $self->alias;

    $self->log->debug("$alias: testing()");

    warn Dumper($args);

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{events} = XAS::Lib::POE::PubSub->new();

    return $self;

}

package App;

use XAS::Lib::Services;
use XAS::Class
  debug   => 0,
  version => '0.01',
  base    => 'XAS::Lib::App',
;

sub main {
    my $self = shift;

    $self->log->info('start run');

    my $service = XAS::Lib::Services->new();
    my $test1 = Test1->new(-alias => 'test1');
    my $test2 = Test2->new(-alias => 'test2');

    $service->register('test1 test2');
    $service->run();

    $self->log->info('stop run');

}


my $app = App->new();
$app->run();

