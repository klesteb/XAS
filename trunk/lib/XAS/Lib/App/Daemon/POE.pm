package XAS::Lib::App::Daemon::POE;

our $VERSION = '0.01';

use POE;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Lib::App::Daemon',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub define_daemon {
    my $self = shift;

    # become a daemon...

    $self->SUPER::define_daemon();
    $poe_kernel->has_forked() if ($self->daemon);

}

sub define_signals {
    my $self = shift;

}

sub signal_handler {
    my $signal = shift;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::App::Daemon::POE - The base class to write daemons that use POE within the XAS environment

=head1 SYNOPSIS

 use XAS::Lib::App::Daemon::POE;

 my $app = XAS::Lib::App::Daemon::POE->new();

 $app->run();

=head1 DESCRIPTION

This module defines a base class for writing daemons with POE. It inherits from
L<XAS::Lib::App::Daemon|XAS::Lib::App::Daemon>. Please see that module for
additional documentation.

=head1 METHODS

=head2 define_signals

This method sets up basic signal handling. Signal handling is done by POE.

=head2 signal_handler($signal)

This method is a default signal handler. Signal processing is done by POE.

=over 4

=item B<$signal>

The signal that was captured.

=back

=head2 define_daemon

This method will cause the proces to become a daemon. It also notifes POE
that the process has forked.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
