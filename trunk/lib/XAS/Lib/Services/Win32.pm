package XAS::Lib::Services::Win32;

our $VERSION = '0.01';

use POE;
use Win32;
use Win32::Daemon;

use XAS::Class
  debug    => 0,
  version  => $VERSION,
  base     => 'XAS::Base',
  mixins   => 'init_service _current_state
               SERVICE_START_PENDING
               SERVICE_STOP_PENDING SERVICE_PAUSE_PENDING
               SERVICE_CONTINUE_PENDING SERVICE_CONTROL_SHUTDOWN
               SERVICE_RUNNING SERVICE_STOPPED SERVICE_PAUSED'
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub init_service {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering init_service() - win32");

    unless (Win32::Daemon::StartService()) {

        $self->throw_msg(
            'xas.lib.service.win32.startup.startservice',
            'noservice',
            _get_error()
        );

    }

    $self->log->debug("$alias: leaving init_service() - win32");

}

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _get_error {

    return(Win32::FormatMessage(Win32::Daemon::GetLastError()));

}

sub _current_state {
    my $self = shift;

    my ($state, $delay) = $self->validate_params(\@_, [
        { optional => 1, default => undef },
        { optional => 1, default => 0 },
    ]);

    if (defined($state)) {

        Win32::Daemon::State($state, $delay);

    }

    return Win32::Daemon::State();

}

1;

__END__

=head1 NAME

XAS::Lib::Services::Win32 - A mixin class for Win32 Services

=head1 DESCRIPTION

This module is a mixin that provides an interface between Services and 
the Win32 SCM. It allows POE to manage the scheduling of sessions while
referencing the Win32 SCM event stream.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See L<http://dev.perl.org/licenses/> for more information.

=cut
