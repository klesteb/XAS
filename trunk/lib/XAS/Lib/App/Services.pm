package XAS::Lib::App::Services;

our $VERSION = '0.01';

my $mixin;
BEGIN {
    $mixin = ($^O eq 'MSWin32')
      ? 'XAS::Lib::App::Services::Win32'
      : 'XAS::Lib::App::Services::Unix';
}

use Try::Tiny;
use File::Pid;
use Pod::Usage;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Lib::App',
  mixin      => $mixin,
  constants  => 'TRUE FALSE',
  filesystem => 'File',
  accessors  => 'daemon',
  messages => {
      installed => 'The service was successfully installed.',
      removed   => 'The service was successfully deinstalled.',
      failed    => 'The service action "%s" failed; reason: %s.',
  },
  vars => {
    SERVICE_NAME         => 'XAS_Test',
    SERVICE_DISPLAY_NAME => 'XAS Test',
    SERVICE_DESCRIPTION  => 'This is a test perl service',
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub define_signals {
    my $self = shift;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _default_options {
    my $self = shift;

    my $options = $self->SUPER::_default_options();

    $self->{daemon} = FALSE;
    
    $options->{'daemon'} = \$self->{daemon};

    $options->{'install'}   = sub { 
        $self->install_service(); 
        exit 0; 
    };

    $options->{'deinstall'} = sub { 
        $self->remove_service(); 
        exit 0; 
    };

    $options->{'pidfile=s'} = sub { 
        my $pidfile = File($_[1]); 
        $self->env->pidfile($pidfile);
    };

    $options->{'cfgfile=s'} = sub { 
        my $cfgfile = File($_[1]); 
        $self->env->cfgfile($cfgfile);
    };

    return $options;

}

1;

__END__

=head1 NAME

XAS::Lib::App::Services - The base class to write services within the XAS environment

=head1 SYNOPSIS

 use XAS::Lib::App::Services;

 my $service = XAS::Lib::App::Services->new();

 $service->run();

=head1 DESCRIPTION

This module defines an opeating environment for Services. A service is a 
managed daemon. They behave differently depending on what platform they
are running on. On Windows, they will run under the SCM, on Unix like boxes, 
they may be standalone daemons. These differences are handled by mixins.

The proper mixin is loaded when the process starts, so all the interaction
happens in the background. It inherits from L<XAS::Lib::App>. Please see 
that module for additional documentation.

=head1 OPTIONS

This module handles these additional options.

=head2 B<--cfgfile>

This defines a configuration file.

=head2 B<--pidfile>

This defines the pid file to use.

=head2 B<--install>

This will install the service with the Win32 SCM.

=head2 B<--deinstall>

This will deinstall the service from the Win32 SCM.

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
