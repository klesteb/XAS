#!/usr/bin/perl
# ============================================================================
#             Copyright (c) 2012 Kevin L. Esteb All Rights Reserved
#
#
# TITLE:       echo-client.pl
#
# FACILITY:    XAS 
#
# ABSTRACT:    This implements a simple "echo" client.
#
# ENVIRONMENT: Linux/AIX Perl Environment
#
# PARAMETERS:  --help    prints out a helpful help message
#              --manual  prints out the procedures manual
#              --version prints out the procedures version
#              --debug   toggles debug output
#
# RETURNS:     0 - success
#              1 - failure
#
# Version      Author                                              Date
# -------      ----------------------------------------------      -----------
# 0.01         Kevin Esteb                                         02-Apr-2009
#
# 0.02         Kevin Esteb                                         10-Jul-2012
#              Updated the help/version/manual switches to use
#              pod for the output text.
#
# 0.03         Kevin Esteb                                         08-Aug-2012
#              Changed over to the new app framework.
#
# ============================================================================
#

use lib "../lib";
use XAS::Apps::Test::Echo::Client;

main: {

    my $app = XAS::Apps::Test::Echo::Client->new(
        -throws => 'echo-client',
    );

    exit $app->run();

}

__END__

=head1 NAME

echo-client.pl - this procedure implements a simple echo client

=head1 SYNOPSIS

echo-client.pl [--help] [--debug] [--manual] [--version]

 options:
   --host       the host the echo server resides on
   --port       the port it is listening on
   --send       the message to echo back
   --help       outputs simple help text
   --manual     outputs the procedures manual
   --version    outputs the apps version
   --debug      toogles debugging output
   --[no]alerts toogles alert notification

=head1 DESCRIPTION

This procedure will send the message to the echo server. It will then be
"echoed" back.

=head1 OPTIONS AND ARGUMENTS

=over 4

=item B<--host>

The host the echo server resides on.

=item B<--port>

The port it is listening on.

=item B<--send>

The message to be "echoed" back.

=item B<--help>

Displays a simple help message.

=item B<--debug>

Turns on debbuging.

=item B<--alerts>

Toggles alert notification. The default is on.

=item B<--manual>

The complete documentation.
  
=item B<--version>

Prints out the apps version

=back

=head1 EXIT CODES

 0 - success
 1 - failure

=head1 SEE ALSO

 XAS::Apps::Test::Echo::Server

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
