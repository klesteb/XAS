#!/usr/bin/perl
# ============================================================================
#             Copyright (c) 2014 Kevin L. Esteb All Rights Reserved
#
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
#              --logtype toggles the log type
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
# 0.01         Kevin Esteb                                         02-Apr-2009
#
# ============================================================================
#

use lib "../lib";
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
   --help     outputs simple help text
   --manual   outputs the procedures manual
   --version  outputs the apps version
   --debug    toogles debugging output
   --logtype  toggles the log type
   --alerts   toogles alert notifications

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

=item B<--logtype>

Toggles the log type. Defaults to 'console'. Can be 'console', 'file', 
'logstash' or 'syslog'.

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

=item L<XAS>

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
