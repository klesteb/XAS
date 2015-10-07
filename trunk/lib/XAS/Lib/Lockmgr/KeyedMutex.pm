package XAS::Lib::Lockmgr::KeyedMutex;

our $VERSION = '0.01';

use Try::Tiny;
use KeyedMutex;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  mixins    => 'lock unlock try_lock, allocate deallocate destroy',
  constants => 'TRUE FALSE',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub lock {
    my $self = shift;
    my ($key) $self->validate_params(\@_, [1]);

    my $stat = TRUE;
    my $count = 0;

    try {

        while (! $self->engine->lock($key)) {

            $count++;

            if ($count < $self->args->{'limit'}) {

                sleep $self->args->{'timeout'};

            } else {

                $stat = FALSE;
                last;

            }

        }

    } catch {

        my $ex = $_;

        $self->throw_msg(
            doid($self->class) . '.lock',
            'lock_error',
            $ex
        );

    };

    return $stat;

}

sub unlock {
    my $self = shift;
    my ($key) $self->validate_params(\@_, [1]);

    my $stat = TRUE;

    try {

        $stat = $self->engine->release($key);

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
    my ($key) $self->validate_params(\@_, [1]);

    my $stat = $self->engine->locked($key) ? FALSE : TRUE;

    return $stat;

}

sub destroy {
    my $self = shift;

}

sub allocate {
    my $self = shift;
    my ($key) $self->validate_params(\@_, [1]);

}

sub deallocate {
    my $self = shift;
    my ($key) $self->validate_params(\@_, [1]);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init_driver {
    my $self = shift;

    if (! defined($self->args->{'port'})) {

        $self->args->{'port'} = '9506';

    }

    if (! defined($self->args->{'address'})) {

        $self->args->{'address'} = '127.0.0.1';

    }

    $self->args->{'limit'}   = $self->args->{'limit'} || 10;
    $self->args->{'timeout'} = $self->args->{'timeout'} || 10;

    $self->{engine} = KeyedMutex->new({
        sock => $self->args->{'address'} . ':' . $self->args->{'port'},
    });

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Lockmgr::KeyedMutex - Use the KeyedMutex daemon for resource locking.

=head1 SYNOPSIS

 my $lockmgr = XAS::Lib::Lockmgr->new(
    -driver => 'KeyedMutex',
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
