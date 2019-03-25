#!/usr/bin/perl
# ============================================================================
#
# TITLE:
#
# FACILITY:    XAS
#
# ABSTRACT:
#
# ENVIRONMENT: The XAS Middleware Environment
#
# PARAMETERS:
#              --help         prints out a helpful help message
#              --debug        toggles debug output
#              --alerts       toggles alert notification
#              --manual       prints out the procedures manual
#              --version      prints out the procedures version
#              --priority     change the alerts priority
#              --facility     change the alerts facility
#              --log-file     name of the log file
#              --log-type     toggles the log type
#              --log-facility changes the log facility to use
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

#use lib "../lib";
use XAS::Apps::xxxx;

main: {

    my $app = XAS::Apps::xxxx->new(
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
   --help         outputs simple help text
   --debug        toogles debugging output
   --alerts       toogles alert notifications
   --manual       outputs the procedures manual
   --version      outputs the apps version
   --facility     change the alerts facility
   --priority     change the alerts priority
   --log-file     name of the log file 
   --log-type     toggles the log type
   --log-facility changes the log facility

=head1 DESCRIPTION

This procedure is a simple template to help write standardized procedures.

=head1 CONFIGURATION

Please refer to L<XAS::Apps::xxxx|XAS::Apps::xxxx> for configuration file 
information.

=head1 OPTIONS AND ARGUMENTS

=over 4

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

=item B<--facility>

This changs the alerts facility, It overrides the defaults.

=item B<--priority>

This changes the alerts priority. It overrides the defaults.

=item B<--log-type>

Toggles the log type. Defaults to 'console'. Can be 'console', 'file', 
'json' or 'syslog'. 

=item B<--log-file>

Optional logfile. When specified the log type is set to 'file'.

=item B<--log-facility>

Toggles the log facilty. Defaults to 'local6'. This follows syslog
convention.

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

Copyright (c) 2012-2019 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
