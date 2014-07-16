package XAS::Apps::Logger;

use Try::Tiny;
use XAS::Class
  debug   => 0,
  version => '0.02',
  base    => 'XAS::Lib::App',
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub setup {
    my $self = shift;

}

sub main {
    my $self = shift;

    $self->setup();

    $self->log->info('starting up');
    $self->log->level('debug', 1);
    $self->log->debug('heh debugging is working');
    $self->log->trace('tracing is working');

    sleep(10);

    $self->log->info('shutting down');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps::Logger - A test for logging

=head1 SYNOPSIS

 use XAS::Apps::Logger;

 my $app = XAS::Apps::Logger->new();

 exit $app->run();

=head1 DESCRIPTION

This module is a test for logging.

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
