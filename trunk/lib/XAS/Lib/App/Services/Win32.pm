package XAS::Lib::App::Services::Win32;

our $VERSION = '0.01';

use Win32;
use Win32::Daemon;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  mixins  => 'define_daemon get_service_config install_service remove_service',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub define_daemon {
    my $self = shift;

}

sub get_service_config {
    my $self = shift;

    # here be dragons... the format is important, especially for the path.

    my $script = Win32::GetFullPathName($0);

    return {
        name        =>  "XAS_Test",
        display     =>  "XAS Test",
        path        =>  "\"$^X\" \"$script\"",
        user        =>  '',
        password    =>  '',
        description => 'This is a test Perl service'
    };

}

sub install_service {
    my $self = shift;

    my $config = $self->get_service_config();

    if (Win32::Daemon::CreateService($config)) {

        printf("%s\n", $self->message('installed'));

    } else {

        printf("%s\n", $self->message('failed', 'install', _get_error()));

    }

}

sub remove_service {
    my $self = shift;

    my $config = $self->get_service_config();

    if (Win32::Daemon::DeleteService($config->{name})) {

        printf("%s\n", $self->message('removed'));

    } else {

        printf("%s\n", $self->message('failed', 'remove', _get_error()));

    }

}


# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _get_error {

    return(Win32::FormatMessage(Win32::Daemon::GetLastError()));

}

1;

__END__

=head1 NAME

XAS::Lib::App::Services::Win32 - A mixin class for Win32 Services

=head1 DESCRIPTION

This module provides a mixin class to define the necessary functionality for
a Service to run on Win32.

=head1 METHODS

=head2 define_daemon

This method does nothing on Win32.

=head2 get_service_config

This method defines how the service is configured. This is used with the
--install and --deintall command line options. The format is important
and should follow this:

 sub get_service_config {
     my $self = shift;

     my $script = Win32::GetFullPathName($0);

     return {
         name        =>  "XAS_Test",
         display     =>  "XAS Test",
         path        =>  "\"$^X\" \"$script\"",
         user        =>  '',
         password    =>  '',
         description => 'This is a test Perl service'
     };

 }

The user and password can be defined, the path should not be changed. See
L<Win32::Daemon> for more details.

=head2 install_service

This method will install the service with the SCM.

=head2 remove_service

This method will deinstall the service for the SCM.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
