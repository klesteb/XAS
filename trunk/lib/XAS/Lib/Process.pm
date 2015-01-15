package XAS::Lib::Process;

our $VERSION = '0.01';

my $mixin;

BEGIN {
    $mixin = 'XAS::Lib::Process::Unix';
    $mixin = 'XAS::Lib::Process::Win32' if ($^O eq 'MSWin32');    
}

use Set::Light;
use Badger::Filesystem 'Cwd Dir';
use POE qw(Wheel Driver::SysRW Filter::Line);

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::Service',
  mixin     => $mixin,
  utils     => 'dotid',
  mutators  => 'is_active input_handle output_handle status retries',
  accessors => 'pid exit_code exit_signal process ID',
  messages => {
    started_process  => '%s: started process %s',
    paused_process   => '%s: paused process %s',
    stopped_process  => '%s: stopped process %s',
    killed_process   => '%s: killed process %s',
    process_exited   => '%s: process %s exited with a %s',
    location         => '%s: can not find absolution location of %s',
    no_autorestart   => '%s: auto restart disabled',
    nomore_retries   => '%s: no more retries',
    unknown_exitcode => '%s: unknown exit code',
  },
  vars => {
    PARAMS => {
      -command       => 1,
      -auto_start    => { optional => 1, default => 1 },
      -auto_restart  => { optional => 1, default => 1 },
      -environment   => { optional => 1, default => {} },
      -exit_codes    => { optional => 1, default => '0,1' },
      -exit_retries  => { optional => 1, default => 5 },
      -group         => { optional => 1, default => 'nobody' },
      -priority      => { optional => 1, default => 0 },
      -umask         => { optional => 1, default => '0022' },
      -user          => { optional => 1, default => 'nobody' },
      -redirect      => { optional => 1, default => 0 },
      -input_driver  => { optional => 1, default => POE::Driver::SysRW->new() },
      -output_driver => { optional => 1, default => POE::Driver::SysRW->new() },
      -input_filter  => { optional => 1, default => POE::Filter::Line->new(Literal => "\n") },
      -output_filter => { optional => 1, default => POE::Filter::Line->new(Literal => "\n") },
      -directory     => { optional => 1, default => Cwd, isa => 'Badger::Filesystem::Directory' },
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub session_initialize {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_initialize()");

    $poe_kernel->state('get_output',  $self);
    $poe_kernel->state('put_input',   $self);
    $poe_kernel->state('flush_event', $self);
    $poe_kernel->state('error_event', $self);
    $poe_kernel->state('close_event', $self);
    $poe_kernel->state('poll_child',  $self, '_poll_child');
    $poe_kernel->state('child_exit',  $self, '_child_exit');

    # walk the chain

    $self->SUPER::session_initialize();

    $poe_kernel->post($alias, 'session_startup');

    $self->log->debug("$alias: leaving session_initialize()");

}

sub session_startup {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_startup()");

    if ($self->auto_start) {

        $self->start_process();

    }

    # walk the chain

    $self->SUPER::session_startup();

    $self->log->debug("$alias: leaving session_startup()");

}

sub session_pause {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_pause()");

    $self->pause_process();

    # walk the chain

    $self->SUPER::session_pause();

    $self->log->debug("$alias: leaving session_pause()");

}

sub session_resume {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_resume()");

    $self->resume_process();

    # walk the chain

    $self->SUPER::session_resume();

    $self->log->debug("$alias: leaving session_resume()");

}

sub session_stop {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_stop()");

    $self->stop_process();

    # walk the chain

    $self->SUPER::session_stop();

    $self->log->debug("$alias: leaving session_stop()");

}

sub session_shutdown {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_shutdown()");

    $self->kill_process();

    # walk the chain

    $self->SUPER::session_shutdown();

    $self->log->debug("$alias: leaving session_shutdown()");

}

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

sub get_output {
    my ($self, $output, $wheel) = @_[OBJECT,ARG0,ARG1];

    print $output . "\n";

}

sub put_input {
    my ($self, $chunk) = @_[OBJECT,ARG0];

    my @chunks;
    my $driver = $self->input_driver;
    my $filter = $self->input_filter;

    # Avoid big bada boom if someone put()s on a dead wheel.

    unless ($self->input_handle) {

        $self->throw_msg(
            dotid($self->class) . '.put_input.writerr',
            'writerr'.
            'called put() on a wheel without an open INPUT handle' 
        );

    }
 
    push(@chunks, $chunk);

    if ($self->{buffer} = $driver->put($filter->put(\@chunks))) {

        $poe_kernel->select_resume_write($self->input_handle);

    }

    return 0;

}

sub flush_event {
    my ($self, $wheel) = @_[OBJECT,ARG0];

    my $alias = $self->alias;

    $self->log->debug("$alias: flush_event");

}

sub error_event {
    my ($self, $operation, $errno, $errstr, $wheel, $type) = @_[OBJECT,ARG0..ARG4];

    my $alias = $self->alias;

    $self->log->debug( 
        sprintf('%s: error_event - ops: %s, errno: %s, errstr: %s',
                $alias, $operation, $errno, $errstr)
    );

}

sub close_event {
    my ($self, $wheel) = @_[OBJECT,ARG0];

    my $alias = $self->alias;

    $self->log->debug("$alias: close_event");

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _child_exit {
    my ($self, $signal, $pid, $exitcode) = @_[OBJECT,ARG0,ARG1,ARG2];

    my $alias   = $self->alias;
    my $status  = $self->status;
    my $retries = $self->retries;

    $self->{pid}         = undef;
    $self->{exit_code}   = $exitcode >> 8;
    $self->{exit_signal} = $exitcode & 127;

    $self->log->warn_msg('process_exited', $alias, $pid, $self->exit_code);

    if ($status == STOPPED) {

        if ($self->auto_restart) {

            if ($retries < $self->exit_retries) {

                $retries += 1;
                $self->retries($retries);

                if ($self->exit_codes->has($self->exit_code)) {

                    $self->start_process();

                } else {

                    $self->log->warn_msg('unknown_exitcode', $alias);

                }

            } else {

                $self->log->warn_msg('nomore_retries', $alias);

            }

        } else {

            $self->log->warn_msg('no_autorestart', $alias);

        }

    }

}

sub _process_output {
    my $self   = shift;

    my $id         = $self->ID;
    my $is_active  = $self->is_active;
    my $driver     = $self->output_driver;
    my $filter     = $self->output_filter;
    my $output     = $self->output_handle;
    my $state      = ref($self) . "($id) -> select output";

    if ($filter->can('get_one') and $filter->can('get_one_start')) {

        $poe_kernel->state(
            $state,
            sub {
                my ($k, $me, $handle) = @_[KERNEL, SESSION, ARG0];
                if (defined(my $raw_output = $driver->get($handle))) {
                    $filter->get_one_start($raw_output);
                    while (1) {
                        my $next_rec = $filter->get_one();
                        last unless @$next_rec;
                        foreach my $cooked_output (@$next_rec) {
                            $k->call($me, 'get_output', $cooked_output, $id);
                        }
                    }
                } else {
                    $k->call($me, 'error_event', 'read', ($!+0), $!, $id, 'OUTPUT');
                    unless (--$is_active) {
                        $k->call($me, 'close_event', $id);
                    }
                    $k->select_read($output);
                }
            }
        );

    } else {

        $poe_kernel->state(
            $state,
            sub {
                my ($k, $me, $handle) = @_[KERNEL, SESSION, ARG0];
                if (defined(my $raw_output = $driver->get($handle))) {
                    foreach my $cooked_output (@{$filter->get($raw_output)}) {
                        $k->call($me, 'get_output', $cooked_output, $id);
                    }
                } else {
                    $k->call($me, 'error_event', 'read', ($!+0), $!, $id, 'OUTPUT');
                    unless (--$is_active) {
                        $k->call($me, 'close_event', $id);
                    }
                    $k->select_read($output);
                }
            }
        );

    }

    $poe_kernel->select_read($output, $state);

}

sub _process_input {
    my $self = shift;

    my $id          = $self->ID;
    my $driver      = $self->input_driver;
    my $filter      = $self->input_filter;
    my $input       = $self->input_handle;
    my $buffer      = \$self->{buffer};
    my $state       = ref($self) . "($id) -> select input";

    $poe_kernel->state(
        $state,
        sub {
            my ($k, $me, $handle) = @_[KERNEL,SESSION,ARG0]; 
            $$buffer = $driver->flush($handle); 
            # When you can't write, nothing else matters.
            if ($!) {
                $k->call($me, 'error_event', 'write', ($!+0), $!, $id, 'INPUT');
                $k->select_write($handle);
            } else {
                # Could write, or perhaps couldn't but only because the
                # filehandle's buffer is choked. 
                # All chunks written; fire off a "flushed" event.
                unless ($$buffer) {
                    $k->select_pause_write($handle);
                    $k->call($me, 'flush_event', $id);
                }
            }
        }
    );

    $poe_kernel->select_write($input, $state);

    # Pause the write select immediately, unless output is pending.

    $poe_kernel->select_pause_write($input) unless ($buffer);

}

sub DESTROY {
    my $self = shift;

    if ($self->input_handle) {

        $poe_kernel->select_write($self->input_handle);
        $self->input_handle(undef);

    }

    if ($self->output_handle) {

        $poe_kernel->select_read($self->output_handle);
        $self->output_handle(undef);

    }

    POE::Wheel::free_wheel_id($self->ID);

}

sub _resolve_path {
    my $self               = shift;
    my $command            = shift;
    my $is_absolute_re     = shift;
    my $has_dir_element_re = shift;
    my $extensions         = shift;
    my $xpath              = shift;
    
    # Stolen from Proc::Background
    #
    # Make the path to the progam absolute if it isn't already.  If the
    # path is not absolute and if the path contains a directory element
    # separator, then only prepend the current working to it.  If the
    # path is not absolute, then look through the PATH environment to
    # find the executable.  In all cases, look for the programs with any
    # extensions added to the original path name.
  
    my $path;
    
    if ($command =~ /$is_absolute_re/o) {

        foreach my $ext (@$extensions) {

            my $p = "$command$ext";

            if (-f $p and -x _) {

                $path = $p;
                last;

            }

        }
        
        unless (defined $path) {

            $self->throw_msg(
                dotid($self->class) . '.resolve_path.path',
                'location',
                $command
            );

        }

    } else {

        my $cwd = Cwd->path;

        if ($command =~ /$has_dir_element_re/o) {

            my $p1 = "$cwd/$command";

            foreach my $ext (@$extensions) {

                my $p2 = "$p1$ext";

                if (-f $p2 and -x _) {

                    $path = $p2;
                    last;

                }

            }

        } else {

            foreach my $dir (@$xpath) {

                next unless length $dir;

                $dir = "$cwd/$dir" unless $dir =~ /$is_absolute_re/o;
                my $p1 = "$dir/$command";
            
                foreach my $ext (@$extensions) {

                    my $p2 = "$p1$ext";
                    if (-f $p2 and -x _) {

                        $path = $p2;
                        last;

                    }

                }

                last if defined $path;

            }

        }

        unless (defined $path) {

            $self->throw_msg(
                dotid($self->class) . '.resolve_path.path',
                'location',
                $command
            );

        }

    }

    return $path;

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    my @exit_codes = split(',', $self->exit_codes);

    $self->{exit_codes} = Set::Light->new(@exit_codes);
    $self->{ID}         = POE::Wheel::allocate_wheel_id();

    $self->retries(1);
    $self->is_active(1);
    $self->init_process();

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Process - A class for managing processes within the XAS environment

=head1 SYNOPSIS

 use XAS::Lib::Process;

 my $process = XAS::Lib::Process->new(
    -command => 'perl test.pl'
 );
 
 $process->run();

=head1 DESCRIPTION

This class manages a sub process in a platform independent way. Mixins
are loaded to handle the differences between Unix/Linux and Windows.
This module inherits from L<XAS::Lib::Service|XAS::Lib::Service>. Please
refer to that module for additional help. 

=head1 METHODS

=head2 new

This method initialized the module and takes the following parameters:

=over 4

=item B<-command>

The command to run.

=item B<-auto_start>

This indicates wither to autostart the process. The default is true.

=item B<-auto_restart>

This indicates wither to restart the process if it exits. The default
is true.

=item B<-directory>

The optional directory to start the process in. Defaults to the current
directory of the parent process.

=item B<-environment>

Optional, addtional environmnet variables to provide to the process.
The default is none.

=item B<-exit_codes>

Optional exit codes to check for the process. They default to '0,1'.
If the exit code matches, then the process is auto restarted. This should
be a comma delimted list of values.

=item B<-exit_retries>

The optional number of retries for restarting the process. The default
is 5.

=item B<-group>

The group to run the process under. Defaults to 'nobody'. This group
may not be defined on your system. This option is not implemented on Windows.

=item B<-priority>

The optional priority to run the process at. Defaults to 0. This option
is not implemented on Windows.

=item B<-umask>

The optional protection mask for the process. Defaults to '0022'. This
option is not implemented on Windows.

=item B<-user>

The optional user to run the process under. Defaults to 'nobody'. This user
may not be defined on your system. This option is not implemented on Windows.

=item B<-redirect>

This option is used to indicate wither to redirect stdout and stderr
from the child process to the parent and stdin from the parent to the
child process. The redirection combines stderr with stdout. Redirection
is implemented using sockets. This may cause buffering problems with the
child process.

The default is no.

=item B<-input_driver>

The optional input driver to use. Defaults to POE::Driver::SysRW.

=item B<-output_driver>

The optional output driver to use. Defaults to POE::Driver::SysRW.

=item B<-input_filter>

The optional filter to use for input. Defaults to POE::Filter::Line.

=item B<-output_filter>

The optional output filter to use. Defaults to POE::Filter::Line.

=back

=head1 PUBLIC EVENTS

The following public events have been defined. The following arguments
are provided by POE as offsets into the argument array.

=head2 put_input(OBJECT,ARG0)

This event will write a buffer to stdin.

=over 4

=item B<ARGO> is the buffer to write out.

=back

=head2 get_output(OBJECT,ARG0,ARG1)

This event will read a buffer for stdout/stderr.

=over

=item B<ARG0> is the buffer.

=item B<ARG1> is the wheel ID.

=back

=head2 flush_event(OBJECT,ARG0)

This event is fired when a flush event happens on stdin.

=over 4

=item B<ARG0> is the wheel id that the event happened too.

=back

=head2 error_event(OBJECT,ARG0..ARG4)

This event is fired when ever an error occurs.  

=over 4

=item B<ARG0> - the operation that was being performed i.e. read/write

=item B<ARG1> - the errno that occured

=item B<ARG2> - the errstr for that errno

=item B<ARG3> - the wheel ID

=item B<ARG4> - the type i.e. INPUT/OUTPUT

=back

=head2 close_event(OBJECT)

This event is fired when a "close" happens on the sockets.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See L<http://dev.perl.org/licenses/> for more information.

=cut
