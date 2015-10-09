package XAS::Lib::Lockmgr::Mutex::Win32;

our $VERSION = '0.01';

use Win32;
use Try::Tiny;
use Win32::Mutex;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  mixin     => 'XAS::Lib::Mixins::Process::Win32',
  constants => 'TRUE FALSE',
  utils     => 'dotid compress',
  mixins    => 'lock unlock try_lock destroy init_driver',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub lock {
    my $self = shift;

    my $rc;
    my $stat = FALSE;

    for (my $x = 1; $x < $self->args->{'limit'}; $x++) {

        if (defined($rc = $self->{'mutex'}->wait(50))) {

            if ($rc > 0) {

                $stat = TRUE;
                push(@{$self->{'locks'}}, 1);
                last;

            }

            sleep $self->args->{'timeout'};

        } else {

            my $msg = _get_error();

            $self->throw_msg(
                dotid($self->class) . '.lock',
                'lock_error',
                $msg
            );

        }
        
    }

    return $stat;

}

sub unlock {
    my $self = shift;

    while (shift(@{$self->{'locks'})) {

        $self->{'mutex'}->release();

    }

}

sub try_lock {
    my $self = shift;

    my $rc;
    my $stat = FALSE;

    if (defined($rc = $self->{'mutex'}->wait(50))) {

        push(@{$self->{'locks'}}, 1);

        if ($rc >= 0) {

            $stat = TRUE;

        }

    } else {

        my $msg = _get_error();

        $self->throw_msg(
            dotid($self->class) . '.try_lock',
            'lock_error',
            $msg
        );

    }

    return $stat;

}

sub destroy {
    my $self = shift;

    $self->{'mutex'} = undef; # does this work?

}

sub init_driver {
    my $self = shift;

    $self->{'locks'} = ();

    $self->args->{'limit'}   = 10 unless defined($self->args->{'limit'});
    $self->args->{'timeout'} = 10 unless defined($self->args->{'timeout'});

    try {

        # Create the mutex. 

        $self->{'mutex'} = Win32::Mutex->new(1, $self->key);

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

sub _get_error {

    return(compress(Win32::FormatMessage(Win32::GetLastError())));

}

1;

__END__

=head1 NAME

XAS::Lib::Lockmgr::Mutex - Use SysV semaphores for resource locking.

=head1 SYNOPSIS

 use XAS::Lib::Lockmgr;

 my $lockmgr = XAS::Lib::Lockmgr->new(
     -driver => 'Mutex',
     -args => {
         key => 'xas',
     }
 );

 if ($lockmgr->try_lock) {

     $lockmgr->lock;

     ...

     $lockmgr->unlock;

 }

=head1 DESCRIPTION

This mixin uses SysV semaphores as a mutex. 

=head1 CONFIGURATION

=over 4

=item key

This field is mandatory.

=item timeout

The number of seconds to sleep if the lock is not available. Default is 10
seconds.

=item limit

The number of attempts to try the lock. If the limit is passed an exception
is thrown. The default is 10.

=item uid

The uid used to create the semaphore. Defaults to effetive uid.

=item gid

The gid used to create the semaphore. Defaults to effetive gid.

=item mode

The access permissions which is used by the semaphore. Defaults to  0666.

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
