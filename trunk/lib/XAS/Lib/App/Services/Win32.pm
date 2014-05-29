package XAS::Lib::App::Service::Win32;

our $VERSION = '0.01';

use Win32;
use Win32::Daemon;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  mixins  => 'define_daemon get_service_config _install_service 
              _remove_service _get_error',
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

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _install_service {
    my $self = shift;

    my $config = $self->get_service_config();

    if (Win32::Daemon::CreateService($config)) {

        printf("%s\n", $self->message('installed'));

    } else {

        printf("%s\n", $self->message('failed', 'install', $self->_get_error()));

    }

}

sub _remove_service {
    my $self = shift;

    my $config = $self->get_service_config();

    if (Win32::Daemon::DeleteService($config->{name})) {

        printf("%s\n", $self->message('removed'));

    } else {

        printf("%s\n", $self->message('failed', 'remove', $self->_get_error()));

    }

}

sub _get_error {
    my $self = shift;

    return(Win32::FormatMessage(Win32::Daemon::GetLastError()));

}

1;

__END__

=head1 NAME

XAS::Lib::App::Service::Unix - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Lib::Service::Unix;

=head1 DESCRIPTION

=head1 METHODS

=head2 method1

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
