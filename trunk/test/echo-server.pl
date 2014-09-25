#!/usr/bin/perl
# ============================================================================
#             Copyright (c) 2012 Kevin L. Esteb All Rights Reserved
#
#
# TITLE:       echo-server.pl
#
# FACILITY:    XAS
#
# ABSTRACT:    This implements a simple echo server.
#
# ENVIRONMENT: Linux - Perl 5.8.8
#
# PARAMETERS:  
#              --address    the address to bind too.
#              --port       the port to listen on.
#              --logfile    The log file to use.
#              --pidfile    the pid file to use.
#              --daemon     Run as a daemon.
#              --help       Print this help message.
#              --manual     Prints out the procedures manual
#              --version    Prints out the procedures version
#              --debug      Toggles debugging output.
#              --[no]alerts Toggles alert notification
#
# RETURNS:     0 - success
#              1 - failure
#              2 - already running
#
# Version      Author                                              Date
# -------      ----------------------------------------------      -----------
# 0.01         Kevin Esteb                                         07-Jul-2010
#
# 0.02         Kevin Esteb                                         10-Jul-2012
#              Updated the help/version/manual switches to use
#              pod for the output text.
#
# 0.03         Kevin Esteb                                         08-Aug-2012
#              Updated to the new app framework.
#
# ============================================================================
#

use lib "../lib";
use XAS::Apps::Test::Echo::Server;

main: {

    my $app = XAS::Apps::Test::Echo::Server->new(
        -throws => 'echo-server',
    );

    exit $app->run();

}

__END__

=head1 NAME

echo-server.pl - a simple echo server

=head1 SYNOPSIS

echo-server.pl [--help] [--debug] [--manual] [--version]

 options:
   --address    the address to bind too
   --port       the port to listen on
   --logfile    the log file to use
   --pidfile    the pid file to use
   --daemon     too daemonize
   --debug      toggles debugging output
   --help       outputs simple help text
   --manual     outputs the procedures manual
   --version    outputs the apps version
   --[no]alerts toggles alert notification

=head1 DESCRIPTION

This procedure is a simple echo server. Anything that it recieves will be
'echoed' back.

=head1 OPTIONS AND ARGUMENTS

=over 4

=item B<--address>

The address to bind too.

=item B<--port>

The port to listen on.

=item B<--logfile>

The log file to use.

=item B<--pidfile>

the pid file to use.

=item B<--daemon>

Run as a daemon.

=item B<--debug>

Turns on debbuging.

=item B<--help>

Displays a simple help message.

=item B<--manual>

The complete documentation.
  
=item B<--version>

Prints out the apps version

=back

=head1 EXIT CODES

 0 - success
 1 - failure
 2 - already running

=head1 SEE ALSO

 XAS::Apps::Test::Echo::Cient

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
