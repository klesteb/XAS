package XAS::Lib::Lockmgr::Files;

our $VERSION = '0.01';

use Try::Tiny;
use Fcntl qw(:flock);

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Base',
  mixins     => 'lock unlock try_lock, allocate deallocate destroy init_driver',
  utils      => 'dotid numlike',
  filesystem => 'File',
  constants  => 'TRUE FALSE',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub lock {
    my $self = shift;
    my ($key) = $self->validate_params(\@_, [1]);

    my $stat = FALSE;
    my $lock = LOCK_EX | LOCK_NB;
    my $fh = _get_fh($self, $key);

    try {

        for (my $x = 1; $x < $self->args->{'limit'}; $x++) {

            if (flock($fh, $lock)) {

                $stat = TRUE;
                last;

            }

            sleep $self->args->{'timeout'};

        }

    } catch {

        my $ex = $_;

        $self->throw_msg(
            dotid($self->class) . '.lock',
            'lock_error',
            $ex
        );

    };

    return $stat;

}

sub unlock {
    my $self = shift;
    my ($key) = $self->validate_params(\@_, [1]);

    my $stat = FALSE;
    my $lock = LOCK_UN | LOCK_NB;
    my $fh = _get_fh($self, $key);

    try {

        for (my $x = 1; $x < $self->args->{'limit'}; $x++) {

            if (flock($fh, $lock)) {

                $stat = TRUE;
                last;

            }

            sleep $self->args->{'timeout'};

        }

    } catch {

        my $ex = $_;

        $self->throw_msg(
            dotid($self->class) . '.unlock',
            'lock_error',
            $ex
        );

    };

    return $stat;

}

sub try_lock {
    my $self = shift;
    my ($key) = $self->validate_params(\@_, [1]);

    my $file;
    my $stat = FALSE;

    try {

        $file = _lockfile($self, $key);
        $stat = TRUE if ($file->exists);

    } catch {

        my $ex = $_;

        $self->throw_msg(
            dotid($self->class) . '.try_lock',
            'lock_error',
            $ex
        );

    };

    return $stat;

}

sub destroy {
    my $self = shift;

    my @keys = keys($self->{'locktable'});

    foreach my $key (@keys) {

        $self->deallocate($key);

    }

}

sub allocate {
    my $self = shift;
    my ($key) = $self->validate_params(\@_, [1]);

    my $fh;
    my $gid  = $self->args->{'gid'};
    my $uid  = $self->args->{'uid'};
    my $mask = $self->args->{'mode'};
    my $file = _lockfile($self, $key);

    unless ($file->exists) {

        $fh = $file->open('w') or do {

            $self->throw_msg(
                dotid($self->class) . '.allocate.creatfile',
                'file_create', 
                $file->path, $!
            );

        };

        $fh->printf("%s:%s\n", $self->env->host, $self->args->{'pid'}) or do {

            $self->throw_msg(
                dotid($self->class) . '.allocate.writefile',
                'file_write', 
                $file->path, $!
            );

        };

    }

    # Change the file permissions to rw-rw-, skip this on Windows 
    # as this will create a read only file.

    if ($^O ne "MSWin32") {

        my ($cnt, $mode, $perms);

        # set file permissions

        $mode  = ($file->stat)[2];
        $perms = sprintf("%04o", $mode & 07777);

        if ($perms ne $mask) {

            $cnt = chmod($mask + 0, $file->path);
            $self->throw_msg(
                dotid($self->class) . '.allocate.invperms',
                'invperms', 
                $file->path) if ($cnt < 1);

        }

        # set file ownership

        $cnt = chown($uid, $gid, $file->path);
        $self->throw_msg(
            dotid($self->class) . '.allocate.invownership',
            'invownership', 
            $file->path) if ($cnt < 1);

    }

    $self->{'locktable'}->{$key}->{'fh'} = $fh;

}

sub deallocate {
    my $self = shift;
    my ($key) = $self->validate_params(\@_, [1]);

    my $file = _lockfile($self, $key);
    my $fh   = $self->{'locktable'}->{$key}->{'fh'};

    if ($file->exists) {

        $fh->close();
        $file->delete();

    }

    delete $self->{'locktable'}->{$key};

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init_driver {
    my $self = shift;

    my $uid;
    my $gid;

    $self->{'locktable'} = {};

    $self->args->{'directory'} = '.'    unless (defined($self->args->{'directory'}));
    $self->args->{'extension'} = '.lck' unless (defined($self->args->{'extension'}));
    $self->args->{'timeout'}   = 10     unless (defined($self->args->{'timeout'}));
    $self->args->{'limit'}     = 10     unless (defined($self->args->{'limit'}));
    $self->args->{'mode'}      = '0660' unless (defined($self->args->{'mode'}));
    $self->args->{'pid'}       = $$     unless (defined($self->args->{'pid'}));

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

}

sub _lockfile {
    my $self = shift;
    my $key  = shift;

    return File($self->args->{'directory'}, $key . $self->args->{'extension'});

}

sub _get_fh {
    my $self = shift;
    my $key  = shift;

    unless (defined($self->{'locktable'}->{$key})) {

        $self->allocate($key);

    }

    return $self->{'locktable'}->{$key}->{'fh'};

}

1;

__END__

=head1 NAME

XAS::Lib::Lockmgr::Files - Use lock files for resource locking.

=head1 SYNOPSIS

 my $lockmgr = XAS::Lib::Lockmgr->new(
    -driver => 'Files',
    -args => {
        port    => 9506,
        address => 127.0.0.1,
        timeout => 10,
        limit   => 10,
    }
 );

 if ($lockmgr->lock($key)) {

     ....

     $lockmgr->unlock($key);

 }

=head1 DESCRIPTION

This implenments general purpose locking using KeyedMutex. KeyedMutex is a 
distributed locking daemon with a perl interface module. 

=head1 CONFIGURATION

=over 4

=item port

The IP port number to talk to the daemon on. Default is 9506.

=item address

The IP address or host name where the daemon is located. Default is 127.0.0.1.

=item timeout

The number of seconds to sleep if the lock is not available. Default is 10
seconds.

=item limit

The number of attempts to try the lock. If the limit is passed an exception
is thrown. The default is 10.

=back

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=item L<KeyedMutex|KeyedMutex>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
