package XAS::Apps::Test::Service;

use XAS::Lib::Service;

use XAS::Class
  version => '0.01',
  base    => 'XAS::Lib::App::Services',
  vars => {
    SERVICE_NAME         => 'XAS_POE_TEST',
    SERVICE_DISPLAY_NAME => 'XAS POE Test',
    SERVICE_DESCRIPTION  => 'This is a test service',
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub main {
    my $self = shift;

    my $service;

    $self->service->register('testing');

    $self->log->info('starting up');

    $service = XAS::Lib::Service->new(-alias => 'testing');
    $service->run();

    $self->log->info('shutting down');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps::Test::Service - A template module for services within the XAS environment

=head1 SYNOPSIS

 use XAS::Apps::Test::Service;

 my $app = XAS::Apps::Test::Service->new();

 exit $app->run();

=head1 DESCRIPTION

This module is a template on a way to write procedures that are services
within the XAS enviornment.

=head1 CONFIGURATION

=head1 SEE ALSO

L< XAS|XAS>

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See L<http://dev.perl.org/licenses/> for more information.

=cut
