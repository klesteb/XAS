package XAS::Lib::Lockmgr::Filesystem;

our $VERSION = '0.01';

use DateTime;
use Try::Tiny;
use Params::Validate qw(HASHREF);

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Base',
  constants  => 'TRUE FALSE',
  utils      => 'dotid',
  filesystem => 'Dir File',
  mixins     => 'lock unlock try_lock break_lock whose_lock destroy init_driver',
  vars => {
    PARAMS => {
      -key  => 1,
      -args => { optional => 1, type => HASHREF, default => {} },
    }
  }
;

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

    try {

        for (my $x = 1; $x < $limit; $x++) {

            unless ($dir->exists) {

                $dir->create;
                $lock->create;
                $stat = TRUE;
                last;

            }

            $self->log->debug("lock: $dir exists");

            sleep $timeout;

        }

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

    try {

        for (my $x = 1; $x < $limit; $x++) {

            if ($dir->exists) {

                $self->log->debug("unlock: $dir exists");

                if ($lock->exists) {

                    $self->log->debug("unlock: our lock file - $lock exists");
                    
                    $lock->delete;
                    $dir->delete;
                    $stat = TRUE;
                    last;

                }

            }

            sleep $timeout;

        }

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

                $file->delete;

            }

            $dir->delete;

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

    my $pid  = '';
    my $host = '';
    my $time = 0;
    my $lock = $self->_lockfile();
    my $dir = Dir($lock->volume, $lock->directory);

    try {

        if ($dir->exists) {

            if (my @files = $dir->files) {

                $host = $files[0]->basename;
                $pid  = $files[0]->extension;
                $time = DateTime->from_epoch(
                    epoch     => ($files[0]->stat)[9], 
                    time_zone => 'local'
                );

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

    if ($lock->exists) {

        $lock->delete;
        $dir->delete;

    }

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    unless (defined($self->args->{'name'})) {

        $self->args->{'name'} = $self->env->host;

    }

    unless (defined($self->args->{'extension'})) {

        $self->args->{'extension'} = ".$$";

    }

    $self->args->{'limit'}   = 10 unless defined($self->args->{'limit'});
    $self->args->{'timeout'} = 10 unless defined($self->args->{'timeout'});

    return $self;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _lockfile {
    my $self = shift;

    return File($self->key, $self->args->{'name'} . $self->args->{'extension'});

}

1;

__END__

=head1 NAME

XAS::Lib::Lockmgr::Filsystem - Use the file system for locking.

=head1 SYNOPSIS

 use XAS::Lib::Lockmgr;

 my $lockmgr = XAS::Lib::Lockmgr->new();

 $lockmgr->add(
     -key    => '/var/run/wpm',
     -driver => 'Filesystem',
 );

 if ($lockmgr->try_lock()) {

     $lockmgr->lock();

     ...

     $lockmgr->unlock();

 }

=head1 DESCRIPTION

This mixin uses the manipulation of directories in the file system as a mutex.

=head1 CONFIGURATION

This module adds the following fields to -args.

=over 4

=back

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
