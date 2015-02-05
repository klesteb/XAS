
use lib '../lib';

package testing;

use XAS::Lib::PidFile;
use XAS::Class
  debug     => 0,
  version   => '0.01',
  base      => 'XAS::Lib::App',
  accessors => 'pid',
  utils     => 'dotid',
;

sub define_pidfile {
    my $self = shift;

    my $script = $self->env->script;
    
    # create a pid file, use it as a semaphore lock file

    $self->log('debug', "entering define_pidfile()");

    $self->{pid} = XAS::Lib::PidFile->new();
    if (my $num = $self->pid->is_running()) {

        $self->throw_msg(
            dotid($self->class). '.define_pidfile.runerr',
            'runerr',
            $script, $num
        );

    }

    $self->pid->write() or 
        $self->throw_msg(
            dotid($self->class) . '.define_pidfile.wrterr',
            'wrterr',
            $self->pid->file
        );

    $self->log('debug', "leaving define_pidfile()");

}

sub main {
    my $self = shift;

    $self->log('info', 'starting up');
    
    sleep(60);
    
    $self->log('info', 'shutting down');
    
}

package main;

my $test = testing->new();

$test->run();
#$test->pid->remove();

