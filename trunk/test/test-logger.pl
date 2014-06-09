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
#              --logfile the log file to use
#              --logcfg  the log configuration file to use
#              --help    prints out a helpful help message
#              --manual  prints out the procedures manual
#              --version prints out the procedures version
#              --debug   toggles debug output
#              --alerts  toggles alert notification
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
use XAS::Apps::Logger;

main: {

    my $app = XAS::Apps::Logger->new();

    exit $app->run();

}

__END__

=head1 NAME

test-logger.pl - a procedure to test logging

=head1 SYNOPSIS

test-logger.pl [--help] [--debug] [--manual] [--version]

 options:
   --logfile  the log file to use, default to stderr
   --logcfg   the log configuration file to use
   --help     outputs simple help text
   --manual   outputs the procedures manual
   --version  outputs the apps version
   --debug    toogles debugging output
   --alerts   toogles alert notifications

=head1 DESCRIPTION

This procedure is a simple test procedure for logging.

=head1 OPTIONS AND ARGUMENTS

=over 4

=item B<--logfile>

The name of the log file to use. Defaults to 'stderr'.

=item B<--logcfg>

A log configuration file. It must be in a format that Log::Log4perl
understands.

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
