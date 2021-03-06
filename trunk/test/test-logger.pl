#!/usr/bin/perl
# ============================================================================
#             Copyright (c) 2013 Kevin L. Esteb All Rights Reserved
#
#
# TITLE:       test-logger.pl
#
# FACILITY:    XAS
#
# ABSTRACT:    This procedure will test logging
#
# ENVIRONMENT: XAS Perl Environment
#
# PARAMETERS:  
#              --log-file     the log file to use
#              --log-type     the log configuration file to use
#              --log-facility sets the logging facility
#              --help         prints out a helpful help message
#              --manual       prints out the procedures manual
#              --version      prints out the procedures version
#              --debug        toggles debug output
#              --alerts       toggles alert notification
#
# RETURNS:     
#              0 - success
#              1 - failure
#
# Version      Author                                              Date
# -------      ----------------------------------------------      -----------
# 0.01         Kevin Esteb                                         26-May-2014
#
# ============================================================================
#

use lib "../lib";
use XAS::Apps::Test::Logger;

main: {

    my $app = XAS::Apps::Test::Logger->new();

    exit $app->run();

}

__END__

=head1 NAME

test-logger.pl - a procedure to test logging

=head1 SYNOPSIS

test-logger.pl [--help] [--debug] [--manual] [--version]

 options:
   --log-file     the log file to use, defaults to console
   --log-type     sets the log type
   --log-facility sets the logging facility
   --help         outputs simple help text
   --manual       outputs the procedures manual
   --version      outputs the apps version
   --debug        toogles debugging output
   --alerts       toogles alert notifications

=head1 DESCRIPTION

This procedure is a simple test procedure for logging.

=head1 OPTIONS AND ARGUMENTS

=over 4

=item B<--log-type>

Toggles the log type. Defaults to 'console'. Can be 'console', 'file', 
'json' or 'syslog'.

=item B<--log-facility>

Toggles the log facilty. Defaults to 'local6'. This follows syslog
convention.

=item B<--log-file>

Optional logfile. When specified the log type is set to 'file'.

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

=over 4

=item L<XAS::Apps::Test::Logging>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
