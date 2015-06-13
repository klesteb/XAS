package XAS::Lib::App::Service;

our $VERSION = '0.01';

my $mixin;

BEGIN {
    $mixin = 'XAS::Lib::App::Service::Unix';
    $mixin = 'XAS::Lib::App::Service::Win32' if ($^O eq 'MSWin32');
}

use Try::Tiny;
use Pod::Usage;
use XAS::Lib::Pidfile;
use XAS::Lib::Service;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Lib::App',
  mixin      => $mixin,
  constants  => 'TRUE FALSE',
  filesystem => 'File',
  utils      => 'dotid',
  accessors  => 'daemon service pid',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub define_signals {
    my $self = shift;

}

sub define_pidfile {
    my $self = shift;

    my $script = $self->env->script;

    $self->log->debug('entering define_pidfile()');

    $self->{pid} = XAS::Lib::Pidfile->new(-pid => $$);

    if (my $num = $self->pid->is_running()) {

        $self->throw_msg(
            dotid($self->class). '.define_pidfile.runerr',
            'runerr',
            $script, $num
        );

    }

    $self->pid->write() or 
        $self->throw_msg(
            dotid($self->class) . '.define_pidfile.wrterr',
            'wrterr',
            $self->pid->file
        );

    $self->log->debug('leaving define_pidfile()');

}

sub run {
    my $self = shift;

    my $rc = $self->SUPER::run();

    $self->pid->remove();

    return $rc;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{service} = XAS::Lib::Service->new();

    return $self;

}

sub _default_options {
    my $self = shift;

    my $options = $self->SUPER::_default_options();

    $self->{daemon}  = FALSE;
    $self->{cfgfile} = $self->env->cfgfile;
    $self->{pidfile} = $self->env->pidfile;

    $options->{'daemon'} = \$self->{daemon};

    $options->{'install'} = sub { 
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

XAS::Lib::App::Service - The base class to write services within the XAS environment

=head1 SYNOPSIS

 use XAS::Lib::App::Service;

 my $service = XAS::Lib::App::Service->new();

 $service->run();

=head1 DESCRIPTION

This module defines an operating environment for Services. A service is a 
managed daemon. They behave differently depending on what platform they
are running on. On Windows, they will run under the SCM, on Unix like boxes, 
they may be standalone daemons. These differences are handled by mixins.

The proper mixin is loaded when the process starts, so all the interaction
happens in the background. It inherits from L<XAS::Lib::App|XAS::Lib::App>. Please see 
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

Copyright (C) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
