package XAS::Lib::App::Service::Unix;

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

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _install_service {
    my $self = shift;

}

sub _remove_service {
    my $self = shift;

}

1;

__END__

=head1 NAME

XAS::Lib::Service::Unix - A class for the XAS environment

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
