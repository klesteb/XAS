#!/usr/bin/perl
# ============================================================================
#             Copyright (c) 2014 Kevin L. Esteb All Rights Reserved
#
#
# TITLE:       test-service.pl
#
# FACILITY:    XAS
#
# ABSTRACT:    A test Win32 service.
#
# ENVIRONMENT: Win32 Perl Environment
#
# PARAMETERS:  
#              --install   install the service
#              --deinstall deinstall the service
#              --help      prints out a helpful help message
#              --manual    prints out the procedures manual
#              --version   prints out the procedures version
#              --debug     toggles debug output
#              --alerts    toggles alert notification
#
# RETURNS:     
#              0 - success
#              1 - failure
#
# Version      Author                                              Date
# -------      ----------------------------------------------      -----------
# 0.01         Kevin Esteb                                         09-Jun-2014
#
# ============================================================================
#

use lib '../lib';
use XAS::Apps::Test::Service;

main: {

	my $app = XAS::Apps::Test::Service->new();

	$app->run();

}

__END__

=head1 NAME

test-service.pl - a test Win32 Service

=head1 SYNOPSIS

test-service.pl [--help] [--debug] [--manual] [--version] [--install] [--deinstall]

 options:
   --install   install the service with the SCM
   --deinstall deinstall the service from the SCM
   --help      outputs simple help text
   --manual    outputs the procedures manual
   --version   outputs the apps version
   --debug     toogles debugging output
   --alerts    toogles alert notifications

=head1 DESCRIPTION

This procedure is a simple template to help write standardized procedures.

=head1 OPTIONS AND ARGUMENTS

=over 4

=item B<--install>

Install the service with the SCM. Only has meaning on Win32.

=item B<--deinstall>

Deinstall the service with the SCM. Only has meaning on Win32.

=item B<--daemon>

Become a daemon, Only had meaning on Unix.

=item B<--help>

Displays a simple help message.

=item B<--debug>

Turns on debbuging.

=item B<--alerts>

Togggles alert notification.

=item B<--manual>

The complete documentation.
  
=item B<--version>

Prints out the apps version

=back

=head1 EXIT CODES

 0 - success
 1 - failure

=head1 SEE ALSO

 XAS::Apps::Templates::Service

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
