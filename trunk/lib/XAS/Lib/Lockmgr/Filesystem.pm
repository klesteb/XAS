package XAS::Lib::Lockmgr::Filesystem;

our $VERSION = '0.01';

use DateTime;
use Try::Tiny;
use XAS::Constants 'TRUE FALSE HASHREF';

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Base',
  utils      => 'dotid',
  import     => 'class',
  filesystem => 'Dir File',
  vars => {
    PARAMS => {
      -key  => 1,
      -args => { optional => 1, type => HASHREF, default => {} },
    }
  }
;

#use Data::Dumper;

# note to self: Don't put $self->log->debug() statements in here, it 
# produces a nice race condidtion.

# ----------------------------------------------------------------------
# Overrides
# ----------------------------------------------------------------------

class('Badger::Filesystem')->methods(
    directory_exists => sub {
        my $self = shift;
        my $dir  = shift;
        my $stats = $self->stat_path($dir) || return; 
        return -d $dir ? $stats : 0;  # don't use the cached stat
    },
    file_exists => sub {
        my $self = shift;
        my $file = shift; 
        my $stats = $self->stat_path($file) || return; 
        return -f $file ? $stats : 0;  # don't use the cached stat
    }
);

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub lock {
    my $self = shift;

    my $stat = FALSE;
    my $lock = $self->_lockfile();
    my $limit = $self->args->{'limit'};
    my $timeout = $self->args->{'timeout'};
    my $dir = Dir($lock->volume, $lock->directory);

    retry {

        if ($^O ne 'MSWin32') {

            # temporarily change the umask to create the 
            # directory and files with correct file permissions

            my $omode = umask(0012);
            $dir->create;
            $lock->create;
            umask($omode);

        } else {

            $dir->create;
            $lock->create;

        }

        $stat = TRUE;

    } retry_if {

        1;  # always retry

    } delay_exp {

        $limit, $timeout * 1000

    } catch {

        my $ex = $_;
        my $msg = (ref($ex) eq 'Badger::Exception') ? $ex->info : $ex;
        
        $self->throw_msg(
            dotid($self->class) . '.lock',
            'lock_error',
            $msg
        );

    };

    return $stat;

}

sub unlock {
    my $self = shift;

    my $stat = FALSE;
    my $lock = $self->_lockfile();
    my $limit = $self->args->{'limit'};
    my $timeout = $self->args->{'timeout'};
    my $dir = Dir($lock->volume, $lock->directory);

    retry {

        if ($dir->exists) {

            if ($lock->exists) {

                $lock->delete if ($lock->exists);
                $dir->delete  if ($dir->exists);
                $stat = TRUE;

            } else {

                $dir->delete if($dir->exists);
                $stat = TRUE;

            }

        }

    } retry_if {

        1;  # always retry

    } delay_exp {

        $limit, $timeout * 1000

    } catch {

        my $ex = $_;
        my $msg = (ref($ex) eq 'Badger::Exception') ? $ex->info : $ex;

        $self->throw_msg(
            dotid($self->class) . '.unlock',
            'lock_error',
            $msg
        );

    };

    return $stat;

}

sub try_lock {
    my $self = shift;

    my $lock = $self->_lockfile();

    return $lock->exists ? FALSE : TRUE;

}

sub break_lock {
    my $self = shift;

    my $lock = $self->_lockfile();
    my $dir = Dir($lock->volume, $lock->directory);

    try {

        if ($dir->exists) {

            foreach my $file (@{$dir->files}) {

                $file->delete if ($file->exists);

            }

            $dir->delete if ($dir->exists);

        }

    } catch {

        my $ex = $_;
        my $msg = (ref($ex) eq 'Badger::Exception') ? $ex->info : $ex;

        $self->throw_msg(
            dotid($self->class) . '.break_lock',
            'lock_error',
            $msg
        );

    };

}

sub whose_lock {
    my $self = shift;

    my $pid  = $$;
    my $host = $self->env->host;
    my $time = DateTime->now(time_zoned => 'local');
    my $lock = $self->_lockfile();
    my $dir = Dir($lock->volume, $lock->directory);

    try {

        if ($dir->exists) {

            if (my @files = $dir->files) {

                # should only be one file in the directory

                if ($files[0]->exists) {

                    $host = $files[0]->basename;
                    $pid  = $files[0]->extension;
                    $time = DateTime->from_epoch(
                        epoch     => ($files[0]->stat)[9], 
                        time_zone => 'local'
                    );

                }

            }

        }

    } catch {

        my $ex = $_;
        my $msg = (ref($ex) eq 'Badger::Exception') ? $ex->info : $ex;

        $self->throw_msg(
            dotid($self->class) . '.whose_lock',
            'lock_error',
            $msg
        );

    };

    return $host, $pid, $time;

}

sub destroy {
    my $self = shift;

    my $lock = $self->_lockfile();
    my $dir = Dir($lock->volume, $lock->directory);
    my ($host, $pid, $time) = $self->whose_lock();

    if (($host eq $self->env->host) && ($pid = $$)) {

        $lock->delete if ($lock->exists);
        $dir->delete  if ($dir->exists);

    }

}

sub DESTROY {
    my $self = shift;

    $self->destroy();

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _lockfile {
    my $self = shift;

    my $extension = ".$$";
    my $name = $self->env->host;

    return File($self->key, $name . $extension);

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);
    my $key  = Dir($self->{'key'});

    if ($key->is_relative) {

        $self->{'key'} = Dir($self->env->locks, $self->{'key'});

    }

    $self->args->{'limit'}   = 10 unless defined($self->args->{'limit'});
    $self->args->{'timeout'} = 10 unless defined($self->args->{'timeout'});

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Lockmgr::Filsystem - Use the file system for locking.

=head1 SYNOPSIS

 use XAS::Lib::Lockmgr;

 my $key = '/var/lock/xas/alerts';
 my $lockmgr = XAS::Lib::Lockmgr->new();

 $lockmgr->add(
     -key    => $key,
     -driver => 'Filesystem',
 );

 if ($lockmgr->try_lock($key)) {

     $lockmgr->lock($key);

     ...

     $lockmgr->unlock($key);

 }

=head1 DESCRIPTION

This class uses the manipulation of directories within the file system as a 
mutex. This leverages the atomicity of creating directories and allows for 
discretionary locking of resources.

=head1 CONFIGURATION

This module uses the following fields in -args.

=over 4

=item B<limit>

The number of attempts to aquire the lock. The default is 10.

=item B<timeout>

The number of seconds to wait between lock attempts. The default is 10.

=back

=head1 METHODS

=head2 lock

Attempt to aquire a lock. This is done by creating a directory and writing
a status file into that directory. Returns TRUE for success, FALSE otherwise.

=head2 unlock

Remove the lock. This is done by removing the status file and then the 
directory. Returns TRUE for success, FALSE otherwise.

=head2 try_lock

Check to see if a lock could be aquired. Returns FALSE if the directory exists,
TRUE otherwise.

=head2 break_lock

Unconditionally remove the contains of the directory and than remove the 
directory.

=head2 whose_lock

Query the status file. This file provides the following information:

=over 4

=item host

=item pid

=item modification time

=back

This information is implicit in the name of the file and the modification time
stored within the filesystem.

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::Lockmgr|XAS::Lib::Lockmgr>

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
