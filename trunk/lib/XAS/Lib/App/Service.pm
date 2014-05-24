package XAS::Lib::App::Service;

our $VERSION = '0.01';

use Win32;
use Try::Tiny;
use File::Pid;
use Pod::Usage;
use Win32::Daemon;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  import     => 'class CLASS',
  base       => 'XAS::Lib::App',
  constants  => 'TRUE FALSE',
  accessors  => 'logfile cfgfile',
  filesystem => 'File',
  messages => {
      installed => 'The service was successfully installed.',
      removed   => 'The service was successfully deinstalled.',
      failed    => 'The service action "%s" failed; reason: %s.',
  },
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub signal_handler {
    my $signal = shift;

    my $ex = XAS::Exception->new(
        type => 'xas.lib.app.signal_handler',
        info => 'process intrupted by signal ' . $signal
    );

    $ex->throw();

}

sub define_signals {
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

sub _default_options {
    my $self = shift;

    my $options = $self->SUPER::_default_options();
    
    $self->{logfile} = $self->env->logfile;
    $self->{cfgfile} = $self->env->cfgfile;
    
    $options->{'install'}   = sub { $self->_install_service(); exit 0; };
    $options->{'deinstall'} = sub { $self->_remove_service(); exit 0; };
    $options->{'cfgfile=s'} = sub { $self->{cfgfile} = File($_[1]); };

    $options->{'logfile=s'} = sub {
        $self->{logfile} = File($_[1]);
        $self->class->var('LOGFILE', $self->logfile->path);
    };

    return $options;

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

XAS::Lib::App::Service - The base class to write services within the XAS environment

=head1 SYNOPSIS

 use XAS::Lib::App::Service;

 my $service = XAS::Lib::App::Service->new();

 $service->run();

=head1 DESCRIPTION

This module defines a base class for writing Win32 Services. It inherits from
XAS::Lib::App. Please see that module for additional documentation.

=head1 METHODS

=head2 get_service_config()

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

=head1 ACCESSORS

The following accessors are defined.

=head2 logfile

This returns the currently defined log file.

=head2 cfgfile

This returns the currently defined config file.

=head1 OPTIONS

This module handles these additional options.

=head2 B<--logfile>

This defines a log file for logging information.

=head2 B<--cfgfile>

This defines a configuration file.

=head2 B<--install>

This will install the service with the Win32 SCM.

=head2 B<--deinstall>

This will deinstall the service from the Win32 SCM.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=item L<Log::Log4perl>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
