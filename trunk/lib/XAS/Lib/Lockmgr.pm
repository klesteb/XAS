package XAS::Lib::Lockmgr;

our $VERSION = '0.03';

use DateTime;
use DateTime::Span;
use Try::Tiny::Retry ':all';
use Params::Validate 'HASHREF';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Singleton',
  mixin     => 'XAS::Lib::Mixins::Process XAS::Lib::Mixins::Handlers',
  utils     => ':validation dotid load_module',
  accessors => 'lockers',
  constants => 'LOCK_DRIVERS TRUE FALSE',
  vars => {
    PARAMS => {
      -deadlocked => { optional => 1, default => 30 },
      -attempts   => { optional => 1, default => 30 },
      -breaklock  => { optional => 1, default => 0 },
      -timeout    => { optional => 1, default => 30 },
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub add {
    my $self = shift;
    my $p = validate_params(\@_, {
        -key    => 1,
        -args   => { optional => 1, default => {}, type => HASHREF },
        -driver => { optional => 1, default => 'Filesystem', regex => LOCK_DRIVERS },
    });

    my $key    = $p->{'key'};
    my $args   = $p->{'args'};
    my $module = 'XAS::Lib::Lockmgr::' . $p->{'driver'};

    unless (defined($self->lockers->{$key})) {

        load_module($module);

        $self->lockers->{$key} = $module->new(-key => $key, -args => $args);

    }

}

sub remove {
    my $self = shift;
    my ($key) = validate_params(\@_, [1]);

    my $stat = FALSE;

    if (my $locker = $self->lockers->{$key}) {

        $stat = $locker->destroy();
        delete $self->lockers->{$key};

    } else {

        $self->throw_msg(
            dotid($self->class) . '.remove.nokey',
            'lock_nokey',
            $key
        );

    }

    return $stat;

}

sub lock {
    my $self = shift;
    my ($key) = validate_params(\@_, [1]);

    my $stat    = FALSE;
    my $timeout = $self->timeout;
    my $limit   = $self->attempts;

    if (my $locker = $self->lockers->{$key}) {

        retry {

            $stat = $locker->lock();

        } retry_if {

            my $ex = $_;
            my $msg;
            my $retry = 1;

            if (ref($ex) && $ex->isa('XAS::Exception')) {

                $msg = sprintf('%s: %s', $ex->type, $ex->info);

                if ($ex->info =~ /path is invalid/) {

                    $retry = 0;

                }

            } else {

                $msg = sprintf('%s', $ex);

            }

            $self->log->debug($msg);
            $retry;  # always retry

        } delay_exp {

            $limit, $timeout * 1000

        } catch {

            $self->log->debug(sprintf('lock: %s', $key));
            $stat = $self->_deadlock($key);

        };

    } else {

        $self->throw_msg(
            dotid($self->class) . '.lock.nokey',
            'lock_nokey',
            $key
        );

    }

    return $stat;

}

sub unlock {
    my $self = shift;
    my ($key) = validate_params(\@_, [1]);

    my $stat = FALSE;

    if (my $locker = $self->lockers->{$key}) {

        $stat = $locker->unlock();

    } else {

        $self->throw_msg(
            dotid($self->class) . '.unlock.nokey',
            'lock_nokey',
            $key
        );

    }

    return $stat;

}

sub try_lock {
    my $self = shift;
    my ($key) = validate_params(\@_, [1]);

    my $stat = FALSE;

    if (my $locker = $self->lockers->{$key}) {

        unless ($stat = $locker->try_lock()) {

            $self->log->warn_msg('lock_dir_error', $key);
            $self->log->debug(sprintf('try_lock: %s', $key));
            $stat = $self->_deadlock($key);

        }

    } else {

        $self->throw_msg(
            dotid($self->class) . '.try_lock.nokey',
            'lock_nokey',
            $key
        );

    }

    return $stat;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _deadlock {
    my $self = shift;
    my ($key) = validate_params(\@_, [1]);

    my $locker;
    my $stat = FALSE;

    my $break_lock = sub {

        if ($self->breaklock) {

            # break the deadlock, irregardless of who owns the lock

            $locker->break_lock();
            $self->log->warn_msg('lock_broken', $key);
            $stat = TRUE;

        } else {

            $self->throw_msg(
                dotid($self->class) . '.deadlock.remote',
                'lock_remote',
                $key

            );

        }

    };

    if ($locker = $self->lockers->{$key}) {

        my $now = DateTime->now(time_zone => 'local');
        my ($host, $pid, $time) = $locker->whose_lock();

        if (defined($host) && defined($pid) && defined($time)) {

            $time->set_time_zone('local');

            my $span = DateTime::Span->from_datetimes(
                start => $now->clone->subtract(minutes => $self->deadlocked),
                end   => $now->clone->add(minutes => 5),
            );

            $self->log->debug(sprintf('deadlock: host  - %s', $host));
            $self->log->debug(sprintf('deadlock: pid   - %s', $pid));
            $self->log->debug(sprintf('deadlock: start - %s', $span->start));
            $self->log->debug(sprintf('deadlock: lock  - %s', $time));
            $self->log->debug(sprintf('deadlock: end   - %s', $span->end));

            if ($span->contains($time)) {

                $self->log->debug('deadlock: within time span');

                if ($host eq $self->env->host) {

                    if ($pid == $$) {

                        $self->log->debug('deadlock: our lock');
                        $stat = TRUE;

                    } else {

                        my $status = $self->proc_status($pid, 'deadlock');

                        unless (($status == 3) || ($status == 2)) {

                            $locker->break_lock();
                            $self->log->warn_msg('lock_broken', $key);
                            $stat = TRUE;

                        }

                    }

                } else {

                    $break_lock->();

                }

            } else {

                $break_lock->();

            }

        } else {

            # unable to retrieve lock information, break the deadlock,
            # irregardless of who owns the lock

            $locker->break_lock();
            $self->log->warn_msg('lock_broken', $key);
            $stat = TRUE;

        }

    } else {

        $self->throw_msg(
            dotid($self->class) . '.deadlock.nokey',
            'lock_nokey',
            $key
        );

    }

    return $stat;

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{'lock_attempts'} = 0;
    $self->{'lockers'} = {};

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Lockmgr - The base class for locking within XAS

=head1 SYNOPSIS

 my $lock = 'testing';
 my $lockmgr = XAS::Lib::Lockmgr->new();

 $lockmgr->add(-key => $lock);

 if ($lockmgr->try_lock($lock)) {

    if ($lockmgr->lock($lock)) {

        ....

        $lockmgr->unlock($lock);

    }

 }

=head1 DESCRIPTION

This module provides a general purpose locking mechanism to protect shared
resources. It is rather interesting to ask a developer how they protect
global shared data. They usually answer, "what do you mean by "global shared
data" ?". Well, for those who understand the need, this module provides it
for XAS.

=head1 METHODS

=head2 new

This method initializes the module. It takes the following parameters:

=over 4

=item B<-deadlocked>

The number of minutes before a lock is considered deadlocked. At which point
an attempt will be made to remove the lock. Defaults to 30.

=item B<-breaklock>

After a deadlock has been detected, break the lock, irregardless of who
owns the lock. Defaults to false. The default will also throw an exception
instead of breaking the lock.

=item B<-attempts>

The number of attempts to aquire the lock. Default to 30.

=item B<-timeout>

The number of seconds to wait between each lock attempt. Defaults to 30.

=back

=head2 add(...)

This method adds a key and defines the module that is used to manage that key.
It takes the following named parameters:

=over 4

=item B<-key>

The name of the key. This parameter is required.

=item B<-driver>

The module that will manage the lock. The default is 'Filesystem'. Which will
load L<XAS::Lib::Lockmgr::Filesystem|XAS::Lib::Lockmgr::Filesystem>.

=item B<-args>

An optional hash reference of arguments to pass to the driver.

=back

=head2 remove($key)

This method will remove the key from management. This will call the destroy
method of the managing module.

=over 4

=item B<$key>

The name of the managed key.

=back

=head2 lock($key)

Aquires a lock, returns true if successful.

=over 4

=item B<$key>

The name of the managed key.

=back

=head2 unlock($key)

Releases the lock. Returns true if successful.

=over 4

=item B<$key>

The name of the managed key.

=back

=head2 try_lock($key)

Tests to see if the lock is available, returns true if the lock is available.

=over 4

=item B<$key>

The name of the managed key.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::Lockmgr::Filesystem|XAS::Lib::Lockmgr::Filesystem>

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
