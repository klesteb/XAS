#!/usr/bin/perl
# ============================================================================
#             Copyright (c) 2014 Kevin L. Esteb All Rights Reserved
#
#
# TITLE:       test-process2.pl
#
# FACILITY:    XAS
#
# ABSTRACT:    Test process creation and maintence
#
# ENVIRONMENT: The XAS Middleware Environment
#
# PARAMETERS:
#              --log-type     toggles the log type
#              --log-facility changes the log facility to use
#              --logfile      name of the log file
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
# 0.01         Kevin Esteb                                         02-Apr-2009
#
# ============================================================================
#

use lib "/home/kevin/dev/XAS/trunk/lib";
use XAS::Apps::Test::Process;

main: {

    my $app = XAS::Apps::Test::Process->new(
        -throws   => 'changeme',
        -facility => 'systems',
        -priority => 'low',
    );

    exit $app->run();

}

__END__

=head1 NAME

changeme - the great new changeme procedure

=head1 SYNOPSIS

changeme [--help] [--debug] [--manual] [--version]

 options:
   --help        outputs simple help text
   --manual      outputs the procedures manual
   --version     outputs the apps version
   --debug       toogles debugging output
   --logfile     name of the log file 
   --log-type    toggles the log type
   --log-facilty changes the log facility
   --alerts      toogles alert notifications

=head1 DESCRIPTION

This procedure is a simple template to help write standardized procedures.

=head1 OPTIONS AND ARGUMENTS

=over 4

=item B<--help>

Displays a simple help message.

=item B<--debug>

Turns on debbuging.

=item B<--alerts>

Togggles alert notification.

=item B<--log-type>

Toggles the log type. Defaults to 'console'. Can be 'console', 'file', 
'json' or 'syslog'.

=item B<--log-facility>

Toggles the log facilty. Defaults to 'local6'. This follows syslog
convention.

=item B<--logfile>

Optional logfile. When specified the logtype is set to 'file'.

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

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
