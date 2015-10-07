package XAS::Lib::Lockmgr::UnixMutex;

our $VERSION = '0.01';

use Try::Tiny;
use IPC::Semaphore;
use Errno qw( EAGAIN EINTR );
use IPC::SysV qw( IPC_CREAT IPC_RMID IPC_SET SEM_UNDO IPC_NOWAIT );

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base',
  constants => 'TRUE FALSE LOCK',
  utils     => 'numlike textlike dotid',
  mixins    => 'lock unlock try_lock allocate deallocate destroy init_driver',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub allocate {
    my $self = shift;
    my ($key) = $self->validate_params(\@_, [1]);

    my $size = $self->args->{'nsems'};

    if (scalar($self->{'locktable'})) < $size) {

        unless (grep { $_ eq $key } @$self->{'locktable'}) {

            push(@{$self->{'locktable'}}, $key);

        }

    } else {

        $self->throw_msg(
            dotid($self->class) . '.allocate',
            'lock_allocate',
            $ex
        );

    }

}

sub deallocate {
    my $self = shift;
    my ($key) = $self->validate_params(\@_, [1]);

    my @keys;
    my $semano = _get_semano($self, $key);

    try {

        if ($semano) {

            _unlock_semaphore($self, $semano);

            @keys = grep { $_ ne $key } $self->{'locktable'};
            $self->{'locktable'} = \@keys;
            
        }

    } catch {

        my $ex = $_;

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

    my $semno = _get_semano($self, $key);

    return _lock_semaphore($self, $semno);

}

sub unlock {
    my $self = shift;
    my ($key) = $self->validate_params(\@_, [1]);

    my $semno = _get_semano($self, $key);

    return _unlock_semaphore($self, $semno);

}

sub try_lock {
    my $self = shift;
    my ($key) = $self->validate_params(\@_, [1]);

    my $semno = _get_semano($self, $key);

    return $self->{'engine'}->getncnt($semno) ? FALSE : TRUE;

}

sub destroy {
    my $self = shift;

    if (defined($self->{'engine'})) {

        $self->{'engine'}->remove();

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

    $self->{'locktable'} = ();

    unless (defined($self->args->{'mode'})) {

        # We are being really liberal here... but apache pukes on the
        # defaults.

        $mode = ( 0666 | IPC_CREAT ); 

    }

    if (defined($self->args->{'uid'})) {

        $uid = $self->args->{'uid'};

        unless (numlike($self->args->{'uid'})) {

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

    $self->args->{'key'} = 'xas' unless defined $self->args->{'key'};

    if (textlike($self->args->{'key'})) {

        my $hash;
        my $name = $self->args->{'key'};
        my $len = length($name);

        for (my $x = 0; $x < $len; $x++) {

            $hash += ord(substr($name, $x, 1));

        }

        $self->args->{'key'} = $hash;

    }

    $self->args->{'limit'}   = 10 unless (defined($self->args->{'limit'}));
    $self->args->{'timeout'} = 10 unless (defined($self->args->{'timeout'}));

    try {

        $self->{'engine'} = IPC::Semaphore->new(
            $self->args->{'key'},
            $self->args->{'nsems'},
            $mode
        ) or do {

            $self->throw_msg(
                dotid($self->class) . '.init.nosemaphore',
                'lock_nosemaphore',
                $!
            );

        };

        if ((my $rc = $self->{'engine'}->set(uid => $uid, gid => $gid)) != 0) {

            $self->throw_msg(
                dotid($self->class) . '.init.ownership',
                'lock_sema_ownership',
                $rc
            );

        };

        $self->{'engine'}->setall((1) x $self->args->{'nsems'}) or do {

            $self->throw_msg(
                dotid($self->class) . '.init.semawrite',
                'lock_sema_write',
                $!
            );

        }

    } catch {

        my $ex = $_;

        $self->throw_msg(
            dotid($self->class) . '.unixmutex',
            'lock_semaphores',
            $ex
        );

    };

    return $self;

}

sub _get_semano {
    my $self = shift;
    my $key  = shift;

    my @keys = grep { $_ eq $key } $self->{'locktable'};            

    if (scalar(@keys) > 1) {

        $self->throw_msg(
            dotid($self->class) . '.get_sema.duplicates',
            'lock_duplicates',
            $key
        );

    }

    return $keys[0];

}

sub _lock_semaphore {
    my $self  = shift;
    my $semno = shift;

    my $count = 0;
    my $stat = FALSE;
    my $flags = ( SEM_UNDO | IPC_NOWAIT );

    for (my $x = 1; $x < $self->args->{'limit'}; $x++) {

        my $result = $self->{'engine'}->op($semno, -1, $flags);
        my $ex = $!;

        if (($result == 0) && ($ex == EAGAIN)) {

            sleep $self->args->{'timeout'};
            next;

        }

        $stat = TRUE;
        last;

    }

    return $stat;

}

sub _unlock_semaphore {
    my $self  = shift;
    my $semno = shift;

    $self->{'engine'}->op($semno, 1, SEM_UNDO) or do {

        $self->throw_msg(
            dotid($self->class) . '.unlock_semaphore',
            'lock_sema_release',
            $1
        );

    };

}

1;

__END__

=head1 NAME

XAS::Lib::Lockmgr::UnixMutex - Use SysV semaphores for resource locking.

=head1 SYNOPSIS

 my $lockmgr = XAS::Lib::Lockmgr->new(
    -driver => 'UnixMutex',
    -args => {
        key     => 'xas',
        nsems   => 8,
        timeout => 10,
        limit   => 10,
        gid     => 100,
        uid     => 100,
        mode    => 0666,
    }
 );

 if ($lockmgr->lock($key)) {

     ....

     $lockmgr->unlock($key);

 }

=head1 DESCRIPTION

This implenments general purpose resource locking with SysV semaphores. 

=head1 CONFIGURATION

=over 4

=item key

This is a numeric key to identify the semaphore set. The default is a hash
of "xas".

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
