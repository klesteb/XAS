package XAS::Lib::Lockmgr::UnixMutex;

our $VERSION = '0.01';

use Try::Tiny;
use IPC::Semaphore;
use XAS::Lib::Lockmgr::SharedMem;
use Errno qw( EAGAIN EINTR );
use IPC::SysV qw( IPC_CREAT IPC_RMID IPC_SET SEM_UNDO IPC_NOWAIT );

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  constants => 'TRUE FALSE LOCK',
  utils     => 'numlike textlike dotid',
  constant => {
    BUFSIZ => 256,
  },
;

# ----------------------------------------------------------------------
# Constant Variables
# ----------------------------------------------------------------------

my $BLANK = pack('A256', '');
my $LOCK  = pack('A256', LOCK);

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub allocate {
    my $self = shift;
    my ($key) = $self->validate_params(\@_, [1]);

    my $buffer;
    my $skey = pack('A256', $key);
    my $size = $self->args->{'nsems'};

    try {

        if (_lock_semaphore($self, 0)) {

            for (my $x = 1; $x < $size; $x++) {

                $buffer = $self->{'shmem'}->read($x, BUFSIZ) or die $!;
                if ($buffer eq $BLANK) {

                    $self->{'shmem'}->write($skey, $x, BUFSIZ) or die $!;
                    last;

                }

            }

            _unlock_semaphore($self, 0);

        } else {

            die 'unable to aquire the base lock';

        }

    } catch {

        my $ex = $_;

        _unlock_semaphore($self, 0);
        $self->throw_msg(
            dotid($self->class) . '.allocate',
            'lock_allocate',
            $ex
        );

    };

}

sub deallocate {
    my $self = shift;
    my ($key) = $self->validate_params(\@_, [1]);

    my $buffer;
    my $skey = pack('A256', $key);
    my $size = $self->args->{'nsems'};

    try {

        if (_lock_semaphore($self, 0)) {

            for (my $x = 1; $x < $size; $x++) {

                $buffer = $self->{'shmem'}->read($x, BUFSIZ) or die $!;
                if ($buffer eq $skey) {

                    $self->{'shmem'}->write($BLANK, $x, BUFSIZ) or die $!;
                    last;

                }

            }

            _unlock_semaphore($self, 0);

        } else {

            die 'unable to aquire the base lock';

        }

    } catch {

        my $ex = $_;

        _unlock_semaphore($self, 0);
        $self->throw_msg(
            dotid($self->class) . '.deallocate',
            'lock_deallocate',
            $ex
        );

    };

}

sub lock {
    my $self = shift;
    my ($key) = $self->validate_params(\@_, [1]);

    my $stat;
    my $semno;

    if (($semno = _get_semaphore($self, $key)) > 0) {

        $stat = _lock_semaphore($self, $semno);

    } else {

        $stat = FALSE;

    }

    return $stat;

}

sub unlock {
    my $self = shift;
    my ($key) = $self->validate_params(\@_, [1]);

    my $semno;

    if (($semno = _get_semaphore($self, $key)) > 0) {

        _unlock_semaphore($self, $semno);

    }

}

sub try_lock {
    my $self = shift;
    my ($key) = $self->validate_params(\@_, [1]);

    my $semno;
    my $stat = FALSE;

    if (($semno = _get_semaphore($self, $key)) > 0) {

        $stat = $self->{'engine'}->getncnt($semno) ? FALSE : TRUE;

    }

    return $stat;

}

sub destroy {
    my $self = shift;

    if (defined($self->{engine})) {

        $self->{'engine'}->remove();

    }

    if (defined($self->{shmem})) {

        $self->{'shmem'}->remove();

    }

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init_driver {
    my $self = shift;

    my $gid;
    my $uid;
    my $mode;
    my $size;
    my $buffer;

    unless (defined($aelf->args->{'mode'})) {

        # We are being really liberal here... but apache pukes on the
        # defaults.

        $mode = ( 0666 | IPC_CREAT ); 

    }

    if (defined($self->args->{'uid'})) {

        $uid = $self->args->{'gid'};

        unless (numlike($self->args->{'gid'})) {

            $uid = getpwnam($self->args->{'uid'});

        }

    } else {

        $uid = $>;

    }

    if (defined($self->args->{'gid'})) {

        $gid = $self->args->{'gid'};

        unless (numlike($self->args->{'gid'})) {

            $gid = getgrnam($self->args->{'gid'});

        }

    } else {

        $gid = $);

    };

    if (! defined($self->args->{'nsems'})) {

        if ($^O eq "aix") {

            $self->args->{'nsems'} = 250;

        } elsif ($^O eq 'linux') {

            $self->args->{'nsems'} = 250;

        } elsif ($^O eq 'bsd') {

            $self->args->{'nsems'} = 8;

        } else {

            $self->args->{'nsems'} = 16;

        }

    }

    $self->args->{'key'} = 'xas' unless defined($self->args->{'key'}));

    if (textlike($self->args->{'key'})) {

        my $hash;
        my $name = $self->args->{'key'};
        my $len = length($name);

        for (my $x = 0; $x < $len; $x++) {

            $hash += ord(substr($name, $x, 1));

        }

        $self->args->{'key'} = $hash;

    }

    $self->args->{'limit'}   = 10 unless defined($self->args->{'limit'}));
    $self->args->{'timeout'} = 10 unless defined($self->args->{'timeout'}));

    try {

        $self->{'engine'} = IPC::Semaphore->new(
            $self->args->{'key'},
            $self->args->{'nsems'},
            $mode
        ) or die $!;

        if ((my $rc = $self->{'engine'}->set(uid => $uid, gid => $gid)) != 0) {

            die "unable to set ownership on shared memory - $rc";

        };

        $self->{'engine'}->setall((1) x $self->args->{'nsems'}) or die $!;

    } catch {

        my $ex = $_;

        $self->throw_msg(
            dotid($self->class) . '.init_driver',
            'lock_nosemaphores',
            $ex
        );

    };

    try {

        $size = $self->args->{'nsems'} * BUFSIZ;

        $self->{'shmem'} = XAS::Lockmgr::SharedMem->new(
            $config->{key}, 
            $size, 
            $mode
        ) or die $!;

        if ((my $rc = $self->{'shmem'}->set(uid => $uid, gid => $gid)) != 0) {

            die "unable to set ownership on shared memory - $rc";

        };

        $buffer = $self->{'shmem'}->read(0, BUFSIZ) or die $!;
        if ($buffer ne $LOCK) {

            $self->{'shmem'}->write($LOCK, 0, BUFSIZ) or die $!;

            for (my $x = 1; $x < $config->{nsems}; $x++) {

                $self->{'shmem'}->write($BLANK, $x, BUFSIZ) or die $!;

            }

        }

    } catch {

        my $ex = $_;

        $self->throw_msg(
            dotid($self->class) . '.init_driver',
            'lock_nosharedmem',
            $ex
        );

    };

    return $self;

}

sub _get_semaphore {
    my $self = shift;
    my $key  = shift;

    my $buffer;
    my $stat = -1;
    my $skey = pack('A256', $key);
    my $size = $self->args->{'nsems'};

    try {

        if (_lock_semaphore($self, 0)) {

            for (my $x = 1; $x < $size; $x++) {

                $buffer = $self->{'shmem'}->read($x, BUFSIZ) or die $!;
                if ($buffer eq $skey) {

                    $stat = $x;
                    last;

                }

            }

            _unlock_semaphore($self, 0);

        } else {

            die 'unable to aquire the base lock';

        }

    } catch {

        my $ex = $_;

        _unlock_semaphore($self, 0);
        $self->throw_msg(
            dotid($self->class) . '.get_semaphore.shmread',
            'lock_shmread',
            $ex
        );

    };

    return $stat;

}

sub _lock_semaphore {
    my $self = shift;
    my $semno = shift;

    my $count = 0;
    my $stat = TRUE;
    my $flags = ( SEM_UNDO | IPC_NOWAIT );

    LOOP: {

        my $result = $self->{'engine'}->op($semno, -1, $flags);
        my $ex = $!;

        if (($result == 0) && ($ex == EAGAIN)) {

            $count++;

            if ($count < $self->args->{'limit'}) {

                sleep $self->args->{'timeout'};
                next LOOP;

            } else {

                $stat = FALSE;

            }

        }

    }

    return $stat;

}

sub _unlock_semaphore {
    my $self  = shift;
    my $semno = shift;

    $self->{'engine'}->op($semno, 1, SEM_UNDO) or die $!;

}

1;

__END__

=head1 NAME

XAS::Lockmgr::UnixMutex - Use SysV semaphores for resource locking.

=head1 SYNOPSIS

 use XAS::Server;
 use XAS::Lockmgr::UnixMutex;

 my $psgi_handler;

 main: {

    my $server = XAS::Server->new(
        lockmgr => XAS::Lockmgr::UnixMutex->new(
            key     => 1234,
            nsems   => 32,
            timeout => 10,
            limit   => 10
        },
    );

    $psgi_hander = $server->engine->psgi_handler();

 }

=head1 DESCRIPTION

This implenments general purpose resource locking with SysV semaphores. 

=head1 CONFIGURATION

=over 4

=item key

This is a numeric key to identify the semaphore set. The default is a hash
of "scaffold".

=item nsems

The number of semaphores in the semaphore set. The default is dependent 
on platform. 

    linux - 250
    aix   - 250
    bsd   - 8
    other - 16

=item timeout

The number of seconds to sleep if the lock is not available. Default is 10
seconds.

=item limit

The number of attempts to try the lock. If the limit is passed an exception
is thrown. The default is 10.

=item uid

The uid used to create the semaphores and shared memory segments. Defaults to
effetive uid.

=item gid

The gid used to create the semaphores and shared memory segments. Defaults to
effetive gid.

=item mode

The access permissions which are used by the semaphores and 
shared memory segments. Defaults to ( 0666 | IPC_CREAT ).

=back

=head1 SEE ALSO

=over 4

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
