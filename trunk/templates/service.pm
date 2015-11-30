package XAS::Apps:: ;

our $VERSION = '0.01';

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Lib::App::Service',
  vars => {
    SERVICE_NAME         => 'XAS_Test',
    SERVICE_DISPLAY_NAME => 'XAS Text',
    SERVICE_DESCRIPTION  => 'This is a test Perl service',
  }
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

    $self->log->info_msg('startup');



    $self->service->register('');
    $self->service->run();

    $self->log->info_msg('shutdown');

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

XAS::Apps:: - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Apps:: ;

 my $app = XAS::Apps:: ->new(
     -throws => 'changeme',
 );

 exit $app->run();

=head1 DESCRIPTION

=head1 METHODS

=head2 setup

=head2 main

=head2 options

=head1 SEE ALSO

=over 4

=item L<XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
