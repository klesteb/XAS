package XAS::Lib::Lockmgr::Mutex;

our $VERSION = '0.01';
my $mixin;

BEGIN {
    $mixin = 'XAS::Lib::Lockmgr::Mutex::Unix';
    $mixin = 'XAS::Lib::Lockmgr::Mutex::Win32' if ($^O eq 'MSWin32');    
}

use Params::Validate qw(HASHREF);

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  mixin   => $mixin,
  vars => {
    PARAMS => {
      -key  => 1,
      -args => { type => HASHREF },
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

    $self->init_driver();

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Lockmgr::Mutex - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Lib::Lockmgr;

 my $lockmgr = XAS::Lib::Lockmgr->new();
 
 $lockmgr->add(-key => 'testing', -driver => 'Mutex');

=head1 DESCRIPTION

This module provides a locking mechanism that use native OS primitives. It
is loaded when "-driver" is "Mutex".

=head1 METHODS

=head2 new

This initializes the module and loads the correct mixin depending on the
platform. The two supported platforms are Unix and Win32. It takes the
following named parameters:

=over 4

=item B<-key>

The mandatory key that is used for the lock.

=item B<-args>

The optional hash reference of arguments. These arguments can have the 
following fields:

  limit   - the number of times to attempt locks - default 10
  timeout - the number of seconds to wait between attempts - default 10

=back

=head2 lock

Aquire a lock. This returns true on success.

=head2 unlock

Release the lock. 

=head2 try_lock

This checks if you can aquire a lock.

=head2 destroy

This deallocates the module. It should release any OS resources used.

=head2 init_driver

This initalizes the mixin. It should allocate any OS resources needed.

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
