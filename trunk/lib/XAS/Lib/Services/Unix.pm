package XAS::Lib::Services::Unix;

our $VERSION = '0.01';

use POE;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  constant => {
    SERVICE_START_PENDING    => 1,
    SERVICE_STOP_PENDING     => 2,
    SERVICE_PAUSE_PENDING    => 3,
    SERVICE_CONTINUE_PENDING => 4,
    SERVICE_CONTROL_SHUTDOWN => 5,
    SERVICE_RUNNING          => 6,
    SERVICE_STOPPED          => 7,
    SERVICE_PAUSED           => 8,
  },
  mixins  => 'init_service _current_state session_interrupt
              SERVICE_START_PENDING SERVICE_STOP_PENDING
              SERVICE_PAUSE_PENDING SERVICE_CONTINUE_PENDING
              SERVICE_CONTROL_SHUTDOWN SERVICE_RUNNING
              SERVICE_STOPPED SERVICE_PAUSED',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub init_service {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering init_service() - unix");

    $poe_kernel->sig('CONT', 'session_interrupt');
    $poe_kernel->sig('TSTP', 'session_interrupt');

    $self->log->debug("$alias: leaving int_service() - unix");

}

sub session_interrupt {
    my $self   = shift;
    my $signal = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: session_interrupt()");
    $self->log->warn_msg('signaled', $alias, $signal);

    if ($signal eq 'HUP') {

        $self->session_reload();

    } elsif ($signal eq 'CONT') {

        $poe_kernel->sig_handled();
        $self->_current_state(SERVICE_CONTINUE_PENDING);

    } elsif ($signal eq 'TSTP') {

        $poe_kernel->sig_handled();
        $self->_current_state(SERVICE_PAUSE_PENDING);

    } else { # INT, TERM, QUIT

        $poe_kernel->sig_handled();
        $self->_current_state(SERVICE_CONTROL_SHUTDOWN);

    }

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

sub _current_state {
    my $self = shift;
    my ($state, $delay) = $self->validate_params(\@_, [
        { optional => 1, default => undef },
        { optional => 1, default => 0 },
    ]);

    if (defined($state)) {

        $self->{state} = $state;

    }

    return $self->{state};

}

1;

__END__

=head1 NAME

XAS::Lib::Services::Unix - A mixin class for Unix Services

=head1 DESCRIPTION

This module is a mixin that provides an interface between a Unix like system 
and a Service. It responds to these additional signals.

 TSTP - pause the session
 CONT - resume the session

It allows POE to manage the scheduling of sessions while handling the 
additional signals to emulate the Windows SCM.

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
