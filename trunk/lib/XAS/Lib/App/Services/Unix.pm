package XAS::Lib::App::Services::Unix;

our $VERSION = '0.01';

use POE;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  mixins  => 'define_daemon get_service_config _install_service _remove_service',
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

sub get_service_config {
    my $self = shift;

}

sub install_service {
    my $self = shift;

}

sub remove_service {
    my $self = shift;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Services::Unix - A mixin class for Unix Services

=head1 SYNOPSIS

 use XAS::Lib::Services::Unix;

=head1 DESCRIPTION

This module provides a mixin class to define the necessary functionality for
a Service to run on a Unix like box.

=head1 METHODS

=head2 define_daemon

This method will tell POE that the process has forked.

=head2 get_service_config

This method does nothing on Unix.

=head2 install_service

This method does nothing on Unix.

=head2 remove_service

This method does nothing on Unix.

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
