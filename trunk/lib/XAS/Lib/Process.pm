package XAS::Lib::Process;

our $VERSION = '0.02';

my $mixin;

BEGIN {
    $mixin = 'XAS::Lib::Process::Unix';
    $mixin = 'XAS::Lib::Process::Win32' if ($^O eq 'MSWin32');    
}

use Set::Light;
use Hash::Merge;
use Badger::Filesystem 'Cwd Dir';
use Params::Validate qw(CODEREF);
use POE qw(Wheel Driver::SysRW Filter::Line);

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::POE::Service',
  mixin     => "XAS::Lib::Mixins::Process $mixin",
  utils     => ':validation dotid',
  mutators  => 'input_handle output_handle status retries',
  accessors => 'pid exit_code exit_signal process ID merger',
  constants => ':process',
  vars => {
    PARAMS => {
      -command        => 1,
      -auto_start     => { optional => 1, default => 1 },
      -auto_restart   => { optional => 1, default => 1 },
      -environment    => { optional => 1, default => {} },
      -exit_codes     => { optional => 1, default => '0,1' },
      -exit_retries   => { optional => 1, default => 5 },
      -group          => { optional => 1, default => 'nobody' },
      -priority       => { optional => 1, default => 0 },
      -pty            => { optional => 1, default => 0 },
      -umask          => { optional => 1, default => '0022' },
      -user           => { optional => 1, default => 'nobody' },
      -redirect       => { optional => 1, default => 0 },
      -input_driver   => { optional => 1, default => POE::Driver::SysRW->new() },
      -output_driver  => { optional => 1, default => POE::Driver::SysRW->new() },
      -input_filter   => { optional => 1, default => POE::Filter::Line->new(Literal => "\n") },
      -output_filter  => { optional => 1, default => POE::Filter::Line->new(Literal => "\n") },
      -directory      => { optional => 1, default => Cwd, isa => 'Badger::Filesystem::Directory' },
      -output_handler => { optional => 1, type => CODEREF, default => sub {
              my $output = shift;
              printf("%s\n", $output);
          }
      },
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

    $poe_kernel->state('get_event',    $self, '_get_event');
    $poe_kernel->state('flush_event',  $self, '_flush_event');
    $poe_kernel->state('error_event',  $self, '_error_event');
    $poe_kernel->state('close_event',  $self, '_close_event');
    $poe_kernel->state('check_status', $self, '_check_status');
    $poe_kernel->state('poll_child',   $self, '_poll_child');
    $poe_kernel->state('child_exit',   $self, '_child_exit');

    # walk the chain

    $self->SUPER::session_initialize();

    $poe_kernel->post($alias, 'session_startup');

    $self->log->debug("$alias: leaving session_initialize()");

}

sub session_startup {
    my $self = shift;

    my $count = 1;
    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_startup()");

    if ($self->auto_start) {

        if ($self->status == STOPPED) {

            $self->start_process();
            $poe_kernel->post($alias, 'check_status', $count);

        }

    }

    # walk the chain

    $self->SUPER::session_startup();

    $self->log->debug("$alias: leaving session_startup()");

}

sub session_pause {
    my $self = shift;

    my $count = 1;
    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_pause()");

    $self->pause_process();
    $poe_kernel->post($alias, 'check_status', $count);

    # walk the chain

    $self->SUPER::session_pause();

    $self->log->debug("$alias: leaving session_pause()");

}

sub session_resume {
    my $self = shift;

    my $count = 1;
    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_resume()");

    $self->resume_process();
    $poe_kernel->post($alias, 'check_status', $count);

    # walk the chain

    $self->SUPER::session_resume();

    $self->log->debug("$alias: leaving session_resume()");

}

sub session_stop {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_stop()");

    $self->kill_process();
    $poe_kernel->sig_handled();

    # walk the chain

    $self->SUPER::session_stop();

    $self->log->debug("$alias: leaving session_stop()");

}

sub session_shutdown {
    my $self = shift;

    my $count = 1;
    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_shutdown()");

    $self->status(SHUTDOWN);
    $self->stop_process();

    $poe_kernel->sig_handled();
    $poe_kernel->post($alias, 'check_status', $count);
  
    # walk the chain

    $self->SUPER::session_shutdown();

    $self->log->debug("$alias: leaving session_shutdown()");

}

sub put {
    my $self = shift;
    my ($chunk) = validate_params(\@_, [1]);

    my @chunks;
    my $driver = $self->input_driver;
    my $filter = $self->input_filter;

    # Avoid big bada boom if someone put()s on a dead wheel.

    unless ($self->input_handle) {

        $self->throw_msg(
            dotid($self->class) . '.put_input.writerr',
            'process_writerr',
            'called put() on a wheel without an open INPUT handle' 
        );

    }
 
    push(@chunks, $chunk);

    if ($self->{'buffer'} = $driver->put($filter->put(\@chunks))) {

        $poe_kernel->select_resume_write($self->input_handle);

    }

    return 0;

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

    $self->destroy();

    POE::Wheel::free_wheel_id($self->ID);

}

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _get_event {
    my ($self, $output, $wheel) = @_[OBJECT,ARG0,ARG1];

    $self->output_handler->($output);

}

sub _check_status {
    my ($self, $count) = @_[OBJECT, ARG0];

    my $alias = $self->alias;
    my $stat = $self->stat_process();

    $self->log->debug(sprintf('%s: check_status: process: %s, status: %s, count %s', $alias, $stat, $self->status, $count));

    $count++;

    if ($self->status == STARTED) {

        if (($stat == 3) || ($stat == 2)) {

            $self->status(RUNNING);
            $self->log->info_msg('process_started', $alias, $self->pid);

        } else {

            $poe_kernel->delay('check_status', 5, $count);

        }

    } elsif ($self->status == RUNNING) {

        if (($stat != 3) || ($stat != 2)) {

            $self->resume_process();
            $poe_kernel->delay('check_status', 5, $count);

        }

    } elsif ($self->status == PAUSED) {

        if ($stat != 6) {

            $self->pause_process();
            $poe_kernel->delay('check_status', 5, $count);

        }

    } elsif ($self->status == STOPPED) {

        if ($stat != 0) {

            $self->stop_process();
            $poe_kernel->delay('check_status', 5, $count);

        }

    } elsif($self->status == KILLED) {

        if ($stat != 0) {

            $self->kill_process();
            $poe_kernel->delay('check_status', 5, $count);

        }

    }

}

sub _flush_event {
    my ($self, $wheel) = @_[OBJECT,ARG0];

    my $alias = $self->alias;

    $self->log->debug("$alias: flush_event");

}

sub _error_event {
    my ($self, $operation, $errno, $errstr, $wheel, $type) = @_[OBJECT,ARG0..ARG4];

    my $alias = $self->alias;

    $self->log->debug( 
        sprintf('%s: error_event - ops: %s, errno: %s, errstr: %s',
                $alias, $operation, $errno, $errstr)
    );

}

sub _close_event {
    my ($self, $wheel) = @_[OBJECT,ARG0];

    my $alias = $self->alias;

    $self->log->debug("$alias: close_event");

    $poe_kernel->select_write($self->input_handle);
    $self->input_handle(undef);

    $poe_kernel->select_read($self->output_handle);
    $self->output_handle(undef);

}

sub _child_exit {
    my ($self, $signal, $pid, $exitcode) = @_[OBJECT,ARG0...ARG2];

    my $count   = 1;
    my $alias   = $self->alias;
    my $status  = $self->status;
    my $retries = $self->retries;

    $self->{'pid'}         = undef;
    $self->{'exit_code'}   = $exitcode >> 8;
    $self->{'exit_signal'} = $exitcode & 127;

    $self->log->warn_msg('process_exited', $alias, $pid, $self->exit_code);

    if ($status == STOPPED) {

        if ($self->auto_restart) {

            if (($retries < $self->exit_retries) || ($self->exit_retries < 0)) {

                $retries += 1;
                $self->retries($retries);

                if ($self->exit_codes->has($self->exit_code)) {

                    $self->start_process();
                    $poe_kernel->post($alias, 'check_status', $count);

                } else {

                    $self->log->warn_msg(
                        'process_unknown_exitcode', 
                        $alias,
                        $self->exit_code || '',
                        $self->exit_signal || '',
                    );

                }

            } else {

                $self->log->warn_msg('process_nomore_retries', $alias, $retries);

            }

        } else {

            $self->log->warn_msg('process_no_autorestart', $alias);

        }

    }

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

# stolen from POE::Wheel::Run - more or less

sub _process_output {
    my $self = shift;

    my $id     = $self->ID;
    my $driver = $self->output_driver;
    my $filter = $self->output_filter;
    my $output = $self->output_handle;
    my $state  = ref($self) . "($id) -> select output";

    if ($filter->can('get_one') and $filter->can('get_one_start')) {

        $poe_kernel->state(
            $state,
            sub {
                my ($k, $me, $handle) = @_[KERNEL, SESSION, ARG0];
                if (defined(my $raw = $driver->get($handle))) {
                    $filter->get_one_start($raw);
                    while (1) {
                        my $next_rec = $filter->get_one();
                        last unless @$next_rec;
                        foreach my $cooked (@$next_rec) {
                            $k->call($me, 'get_event', $cooked, $id);
                        }
                    }
                } else {
                    $k->call($me, 'error_event', 'read', ($!+0), $!, $id, 'OUTPUT');
                    $k->call($me, 'close_event', $id);
                    $k->select_read($handle);
                }
            }
        );

    } else {

        $poe_kernel->state(
            $state,
            sub {
                my ($k, $me, $handle) = @_[KERNEL, SESSION, ARG0];
                if (defined(my $raw = $driver->get($handle))) {
                    foreach my $cooked (@{$filter->get($raw)}) {
                        $k->call($me, 'get_event', $cooked, $id);
                    }
                } else {
                    $k->call($me, 'error_event', 'read', ($!+0), $!, $id, 'OUTPUT');
                    $k->call($me, 'close_event', $id);
                    $k->select_read($handle);
                }
            }
        );

    }

    $poe_kernel->select_read($output, $state);

}

sub _process_input {
    my $self = shift;

    my $id     = $self->ID;
    my $driver = $self->input_driver;
    my $filter = $self->input_filter;
    my $input  = $self->input_handle;
    my $buffer = \$self->{'buffer'};
    my $state  = ref($self) . "($id) -> select input";

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

# Stolen from Proc::Background

sub _resolve_path {
    my $self               = shift;
    my $command            = shift;
    my $is_absolute_re     = shift;
    my $has_dir_element_re = shift;
    my $extensions         = shift;
    my $xpath              = shift;

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
                'process_location',
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
                'process_location',
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

    $self->{'exit_codes'} = Set::Light->new(@exit_codes);
    $self->{'ID'}         = POE::Wheel::allocate_wheel_id();
    $self->{'merger'}     = Hash::Merge->new('RIGHT_PRECEDENT');

    $self->retries(1);
    $self->init_process();
    $self->status(STOPPED);

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
This module inherits from L<XAS::Lib::POE::Service|XAS::Lib::POE::Service>. 
Please refer to that module for additional help. 

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

Optional, addtitional environment variables to provide to the process.
The default is none.

=item B<-exit_codes>

Optional exit codes to check for the process. They default to '0,1'.
If the exit code matches, then the process is auto restarted. This should
be a comma delimited list of values.

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

=head2 put_input(OBJECT, ARG0)

This event will write a buffer to stdin.

=over 4

=item B<ARGO> is the buffer to write out.

=back

=head2 get_output(OBJECT, ARG0, ARG1)

This event will read a buffer for stdout/stderr.

=over

=item B<ARG0> is the buffer.

=item B<ARG1> is the wheel ID.

=back

=head2 flush_event(OBJECT, ARG0)

This event is fired when a flush event happens on stdin.

=over 4

=item B<ARG0> is the wheel id that the event happened too.

=back

=head2 error_event(OBJECT, ARG0..ARG4)

This event is fired whenever an error occurs.  

=over 4

=item B<ARG0> - the operation that was being performed i.e. read/write

=item B<ARG1> - the errno that occurred

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

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
