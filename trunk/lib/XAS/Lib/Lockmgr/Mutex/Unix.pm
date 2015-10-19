package XAS::Lib::Lockmgr::Mutex::Unix;

our $VERSION = '0.01';

use Try::Tiny;
use IPC::Semaphore;
use Errno qw( EAGAIN EINVAL );
use IPC::SysV qw( IPC_CREAT SEM_UNDO IPC_NOWAIT );

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  mixin     => 'XAS::Lib::Mixins::Process::Unix',
  constants => 'TRUE FALSE',
  utils     => 'numlike textlike dotid',
  mixins    => 'lock unlock try_lock destroy init_driver',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub lock {
    my $self = shift;

    my $stat  = FALSE;
    my $flags = ( SEM_UNDO | IPC_NOWAIT );

#    $self->log->debug(sprintf('lock - before: %s', $self->{'sema'}->getval(0)));

    for (my $x = 1; $x < $self->args->{'limit'}; $x++) {

        my $rc = $self->{'sema'}->op(0, 1, $flags);
        my $ex = $!;

        $self->log->debug(sprintf('lock - rc: %s, ex: %s', $rc, $ex));

        if (($rc == 0) && ($ex == EAGAIN)) {

            sleep $self->args->{'timeout'};

        } elsif ($rc < 0) {

            $self->throw_msg(
                dotid($self->class) . 'lock',
                'lock_error',
                $ex
            );

        } else {

            $stat = TRUE;
            last;

        }

    }

#    $self->log->debug(sprintf('lock - after: %s', $self->{'sema'}->getval(0)));

    return $stat;

}

sub unlock {
    my $self = shift;

    my $flags = SEM_UNDO;

#    $self->log->debug(sprintf('unlock - before: %s', $self->{'sema'}->getval(0)));

    if ($self->{'sema'}->op(0, -1, $flags) < 0) {

        $self->throw_msg(
            dotid($self->class) . '.unlock',
            'lock_error',
            $!
        );

    }

#    $self->log->debug(sprintf('unlock - after: %s', $self->{'sema'}->getval(0)));

    return 1;

}

sub try_lock {
    my $self = shift;

    return $self->{'sema'}->getncnt(0) ? FALSE : TRUE;

}

sub destroy {
    my $self = shift;

    # If the permissions on the semaphore are not 0666. 
    # This will not remove it. It must be removed with ipcrm.

    if (my $sema = $self->{'sema'}) {

        $sema->remove();
        $self->{'sema'} = undef;

    }

}

sub init_driver {
    my $self = shift;

    my $gid;
    my $uid;
    my $mode;
    my $count = 0;
    my $key = $self->key;

    unless (defined($self->args->{'mode'})) {

        # We are being really liberal here... but apache pukes on the
        # defaults.

        $self->args->{'mode'} = 0666;

    }

    $mode = ($self->args->{'mode'} | IPC_CREAT);

    if (defined($self->args->{'uid'})) {

        $uid = $self->args->{'gid'};

        unless (numlike($self->args->{'gid'})) {

            $uid = getpwnam($self->args->{'uid'});

        }

    } else {

        $uid = $>;

    }

    $self->args->{'uid'} = $uid;

    if (defined($self->args->{'gid'})) {

        $gid = $self->args->{'gid'};

        unless (numlike($self->args->{'gid'})) {

            $gid = getgrnam($self->args->{'gid'});

        }

    } else {

        $gid = $);

    };

    $self->args->{'gid'} = $gid;

    if (textlike($key)) {

        my $hash;
        my $name = $key;
        my $len = length($name);

        for (my $x = 0; $x < $len; $x++) {

            $hash += ord(substr($name, $x, 1));

        }

        $key = $hash;

    }

    $self->args->{'limit'}   = 10 unless defined($self->args->{'limit'});
    $self->args->{'timeout'} = 10 unless defined($self->args->{'timeout'});

    try {

        LOOP: {

            # Create the semaphore. There is a potinential race 
            # condition where another process may also be trying 
            # to create our semaphore. So loop until the return is 
            # defined or the count is exceeded. If count is exceeded, 
            # throw an exception.

            $self->{'sema'} = IPC::Semaphore->new($key, 1, $mode);

            if (defined($self->{'sema'})) {

                # set ownership and the initial value to 0

                my $rc;

                $rc = $self->{'sema'}->set(uid => $uid, gid => $gid);
                die $! unless (defined($rc));
                die $! if ($rc < 0);

                $rc = $self->{'sema'}->setval(0, 0);
                die $! unless (defined($rc));
                die $! if ($rc < 0);

                last LOOP;

            } else {

                $count++;

                if ($count < $self->args->{'limit'}) {

                    sleep $self->args->{'timeout'};
                    next LOOP;

                }

                # unable to aquire a semaphore

                die 'exceeded limit';
            
            }

        };

    } catch {

        my $ex = $_;

        $self->throw_msg(
            dotid($self->class) . '.init_driver',
            'lock_nosemaphores',
            $ex
        );

    };

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Lockmgr::Mutex::Unix - Use SysV semaphores for locking.

=head1 SYNOPSIS

 use XAS::Lib::Lockmgr;

 my $lockmgr = XAS::Lib::Lockmgr->new();

 $lockmgr->add(
     -key    => 'xas',
     -driver => 'Mutex',
     -args => {
         mode => 0600,
         gid  => 'kevin',
         uid  => 'kevin',
     }
 );

 if ($lockmgr->try_lock()) {

     $lockmgr->lock();

     ...

     $lockmgr->unlock();

 }

=head1 DESCRIPTION

This mixin uses SysV semaphores as a mutex. It allocates one semaphore.

=head1 CONFIGURATION

This module adds the following fields to -args.

=over 4

=item B<uid>

The uid used to create the semaphore. Defaults to effetive uid.

=item B<gid>

The gid used to create the semaphore. Defaults to effetive gid.

=item B<mode>

The access permissions for the semaphore. Defaults to 0666.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::Lockmgr::Mutex|XAS::Lib::Lockmgr::Mutex>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
