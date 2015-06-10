package XAS::Lib::Process::Unix;

our $VERSION = '0.01';

use POE;
use Socket;
use IO::Socket;
use POSIX qw(setsid);

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  utils   => ':env dotid compress run_cmd trim',
  mixins  => 'start_process stop_process pause_process resume_process
              stat_process kill_process init_process _parse_command
              _poll_child RUNNING STOPPED PAUSED SHUTDOWN',
  constant => {
    RUNNING  => 0,
    STOPPED  => 1,
    PAUSED   => 2,
    SHUTDOWN => 3,
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub start_process {
    my $self = shift;

    my $pid;
    my $alias     = $self->alias;
    my $umask     = oct($self->umask);
    my $env       = $self->environment;
    my @args      = $self->_parse_command;
    my $priority  = $self->priority;
    my $uid       = getpwnam($self->user);
    my $gid       = getgrnam($self->group);
    my $directory = $self->directory->path;

    $self->log->debug("$alias: command @args");

    my $spawn = sub {

        setsid();           # become a session lead

        eval {              # set priority, fail silently
            my $p = getpriority(0, $$);
            setpriority(0, $$, $p + $priority);
        };

        $( = $) = $gid;     # set new group id
        $< = $> = $uid;     # set new user id

        env_create($env);   # create the new environment

        chdir($directory);  # change directory
        umask($umask);      # set protection mask
        exec(@args);        # become a new process

        exit 0;

    };

    # save the current environment

    my $oldenv = env_store();

    if ($self->redirect) {

        my $child;
        my $parent;

        # create a socket pair

        unless (($child, $parent) = IO::Socket->socketpair(AF_UNIX, SOCK_STREAM, PF_UNSPEC)) {

            $self->throw_msg(
                dotid($self->class) . '.start_process.socketpair',
                'unexpected',
                "unable to create a socketpair, reason: $!"
            );

        }

        unless ($pid = fork()) {

            # child

            unless (defined($pid)) {

                $self->throw_msg(
                    dotid($self->class) . '.start_process.creation',
                    'unexpected',
                    'unable to spawn a new process',
                );

            }

            # close unneeded fd's

            close($child);

            # redirect stdin, stdout and stderr to the parent socket
            # with stderr combined with stdout

            open(STDIN,  '<&', $parent);
            open(STDOUT, '>&', $parent);
            open(STDERR, '>&', $parent);

            # not needed any longer

            close($parent);

            $spawn->();

        } else {

            # parent

            # close unneeded fd's

            close($parent);

            # listen on the child socket

            $self->input_handle($child);
            $self->output_handle($child);

            # setup POE's I/O handling

            $self->_process_output();
            $self->_process_input();

        }

    } else {

        unless ($pid = fork()) {

            # child 

            unless (defined($pid)) {

                $self->throw_msg(
                    dotid($self->class) . '.start_process.creation',
                    'unexpected',
                    'unable to spawn a new process',
                );

            }

            # redirect the standard file handles to dev null

            open(STDIN,  '<', '/dev/null');
            open(STDOUT, '>', '/dev/null');
            open(STDERR, '>', '/dev/null');

            $spawn->();

        }

    }

    $self->status(RUNNING);

    $poe_kernel->sig_child($pid, 'poll_child');
    $self->{pid} = $pid;

    $self->log->info_msg('process_started', $alias, $self->pid);

    # recover the old environment

    env_restore($oldenv);

}

sub stat_process {
    my $self = shift;

    my $stat = 0;

    if (my $pid = $self->pid) {

        my $cmd = "ps -p $pid -o state=";
        my (@output, $rc) = run_cmd($cmd);

        if ($rc == 0) {

            my $line = trim($output[0]);

            # UNIX states
            # from man ps
            #
            #   D    Uninterruptible sleep (usually IO)
            #   R    Running or runnable (on run queue)
            #   S    Interruptible sleep (waiting for an event to complete)
            #   T    Stopped, either by a job control signal or because it 
            #        is being traced.
            #   W    paging (not valid since the 2.6.xx kernel)
            #   X    dead (should never be seen)
            #   Z    Defunct ("zombie") process, terminated but not reaped 
            #        by its parent.

            $stat = 6 if ($line eq 'T');    # suspended ready
            $stat = 5 if ($line eq 'D');    # suspended blocked
#           $stat = 4 if ($line eq '?');    # blocked
            $stat = 3 if ($line eq 'R');    # running
            $stat = 2 if ($line eq 'S');    # ready
            $stat = 1 if ($line eq 'Z');    # other

        }

    }

    return $stat;

}

sub pause_process {
    my $self = shift;

    my $alias = $self->alias;

    if ($self->pid) {

        my $pid = ($self->pid * -1);
        my $code = $self->stat_process();

        if (($code == 3) || ($code == 2)) {   # process is running or ready

            if (kill('TSTP', $pid)) {

                $self->status(PAUSED);
                $self->log->warn_msg('process_paused', $alias, $self->pid);

            }

        }

    }

}

sub resume_process {
    my $self = shift;

    my $alias = $self->alias;

    if ($self->pid) {

        my $pid = ($self->pid * -1);
        my $code = $self->stat_process();

        unless ($code == 6) {   # process is suspended ready

            if (kill('CONT', $pid)) {

                $self->status(RUNNING);
                $self->log->warn_msg('process_started', $alias, $self->pid);

            }

        }

    }

}

sub stop_process {
    my $self = shift;

    my $alias = $self->alias;

    if ($self->pid) {

        my $pid = ($self->pid * -1);

        if (kill('TERM', $pid)) {

            $self->status(STOPPED);
            $self->retries(0);    
            $self->log->warn_msg('process_stopped', $alias, $self->pid);

        }

    }

}

sub kill_process {
    my $self = shift;

    my $alias = $self->alias;

    if ($self->pid) {

        my $pid = ($self->pid * -1);

        if (kill('KILL', $pid)) {

            $self->status(STOPPED);
            $self->retries(0);
            $self->log->warn_msg('process_killed', $alias, $self->pid);

        }

    }

}

sub init_process {
    my $self = shift;

}

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _poll_child {
    my ($self, $signal, $pid, $exitcode) = @_[OBJECT,ARG0,ARG1,ARG2];

    my $alias = $self->alias;

    $self->log->debug("$alias: entering poll_child");

    $self->status(STOPPED);

    # notify 'child_exit' that we are done

    $poe_kernel->post($alias, 'child_exit', 'CHLD', $pid, $exitcode);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _parse_command {
    my $self = shift;

    my @args = split(' ', $self->command);

    my @extensions         = ('');
    my @path               = split(':', $ENV{PATH});
    my $is_absolute_re     = '^/';
    my $has_dir_element_re = "/";
 
    # Stolen from Proc::Background
    #
    # If there is only one element in the @args array, then it may be a
    # command to be passed to the shell and should not be checked, in
    # case the command sets environmental variables in the beginning,
    # i.e. 'VAR=arg ls -l'.  If there is more than one element in the
    # array, then check that the first element is a valid executable
    # that can be found through the PATH and find the absolute path to
    # the executable.  If the executable is found, then replace the
    # first element it with the absolute path.

    if (scalar(@args) > 1) {

        $args[0] = $self->_resolve_path($args[0], $is_absolute_re, $has_dir_element_re, \@extensions, \@path) or return;

    }

    return @args;

}

1;

__END__

=head1 NAME

XAS::Lib::Process::Unix - A mixin class for process management within the XAS environment

=head1 DESCRIPTION

This module is a mixin class to handle the needs for process management
under a Unix like system.

=head1 METHODS

=head2 init_process

This method initializes the module so that it can function properly.

=head2 start_process

This method does the neccessary things to spawn a new process. 

=head2 stat_process

This method returns the status of the process. These are the possible
values.

=over 4

=item B<6>

This status indicates that the process is stopped, either by a
job control signal or it is being traced.

=item B<5>

This status indicates that the process is in a uninterruptible sleep,
usually waiting for I/O.

=item B<4>

Not implemented on Unix.

=item B<3>

This status indicates that the process is running or runnable.

=item B<2>

This indicates that the process is in a interruptible sleep, waiting for
an event to complete.

=item B<1>

This indicates that the process is a zombie. Terminated but not yet
reaped.

=item B<0>

This indicates that the process is in an unknown state.

=back

=head2 stop_process

This method will send a 'TERM' signal to the process.

=head2 pause_process

This method will send a 'TSTP' signal to the process.

=head2 resume_process

This method will send a 'CONT' signal to the process.

=head2 kill_process

This method will send a 'KILL' signal to the process.

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::Process|XAS::Lib::Process>

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
