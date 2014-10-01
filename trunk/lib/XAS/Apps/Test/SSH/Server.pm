package XAS::Apps::Test::SSH::Server;

our $VERSION = '0.01';

use XAS::Lib::SSH::Server;
use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Lib::App',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub setup {
    my $self = shift;

}

sub main {
    my $self = shift;

    $self->setup();

    my $server = XAS::Lib::SSH::Server->new(
        -eol => "\015\012",
    );

    $server->run();

}

sub options {
    my $self = shift;

    return {};

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps::Test::SSH::Server - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Apps::Test::SSH::Server;

 my $app = XAS::Apps::Test::SSH::Server->new(
     -throw => 'ssh-server'
 );

 $app->run();

=head1 DESCRIPTION

This module provides a simple echo server for a SSH channel.

=head1 METHODS

=head2 setup

=head2 main

=head2 options

=head1 SEE ALSO

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See L<http://dev.perl.org/licenses/> for more information.

=cut
