package XAS::Lib::Lockmgr;

our $VERSION = '0.01';

use Params::Validate 'HASHREF';

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  vars => {
    PARAMS => {
      -driver => { optional => 1, default => 'Files' },
      -args   => { optional => 1, default => {}, type => HASHREF },
    }
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub DESTROY {
    my $self = shift;

    $self->destroy();

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    my $args   = $self->args;
    my $driver = 'XAS::Lib::Lockmgr::' . $self->driver;

    $self->class->mixin($driver);
    $self->init_driver();

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Lockmgr - The base class for locking within XAS

=head1 SYNOPSIS

 my $lockmgr = XAS::Lib::Lockmgr->new();

 if ($lockmgr->try_lock($lock)) {

    if ($lockmgr->lock($lock)) {

        ....

        $lockmgr->unlock($lock);

    }

 }

=head1 DESCRIPTION

This module provides a general purpose locking mechanism to protect shared 
resources. It is rather interesting to ask a developer how they protect 
session data and/or global shared data. They usually answer, "I use 
such-and-such session module, and what do you mean by "global shared data" ?". 
Well, for those who understand the need for resource locking, this module 
provides it for XAS.

=head1 METHODS

=over 4

=item allocate($key)

Reserve a lock by this name. This needs to be done before a lock is used.
This name can be used when trying to lock and unlock resources.

=item deallocate($key)

Removes the reservation for the name. This frees up a lock that can be 
subseqently reused.

=item lock($key)

Aquires a lock on a resource, return true if successful.

=item unlock($key)

Releases the lock on a resource.

=item try_lock($key)

Tests to see if the lock on a resource is available, returns true if the lock
is available.

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
