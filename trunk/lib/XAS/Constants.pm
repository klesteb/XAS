package XAS::Constants;

our $VERSION = '0.02';

use Badger::Exporter;

use Badger::Class
  debug   => 0,
  version => $VERSION,
  base    => 'Badger::Constants',    # grab the badger constants
  constant => {
      XAS_QUEUE  => '/queue/xas',

      # Supervisor

      START      => 'start',
      STOP       => 'stop',
      EXIT       => 'exit',
      RELOAD     => 'reload',
      STAT       => 'stat',
      #
      RUNNING    => 'running',
      ALIVE      => 'alive',
      DEAD       => 'dead',
      NOCMD      => 'nocmd',
      #
      STOPPED    => 'stopped',
      STARTED    => 'started',
      RELOADED   => 'reloaded',
      STATED     => 'stated',
      EXITED     => 'exited',
      #
      SHUTDOWN   => 'shutdown',
      KILLME     => 'killme',
      PROC_ROOT  => '/proc',

      # JSON RPC

      RPC_JSON            => '2.0',
      RPC_DEFAULT_ADDRESS => '127.0.0.1',
      RPC_DEFAULT_PORT    => '9505',
      RPC_ERR_PARSE       => -32700,
      RPC_ERR_REQ         => -32600,
      RPC_ERR_METHOD      => -32601,
      RPC_ERR_PARAMS      => -32602,
      RPC_ERR_INTERNAL    => -32603,
      RPC_ERR_SERVER      => -32099,
      RPC_ERR_APP         => -32001,
      RPC_SRV_ERR_MIN     => -32000,
      RPC_SRV_ERR_MAX     => -32768,

      # logging

      LOG_LEVELS   => qr/info|warn|error|fatal|debug|trace/,
      LOG_TYPES    => qr/console|file|logstash|syslog/,
      LOG_FACILITY => qr/auth|authpriv|cron|daemon|ftp|local[0-7]|lpr|mail|news|user|uucp/,

      # alerts

      ALERT_PRIORITY => qr/low|medium|high|info/i,
      ALERT_FACILITY => qr/systems/i,

  },
  exports => {
      all => q/RPC_JSON RPC_DEFAULT_PORT RPC_DEFAULT_ADDRESS RPC_ERR_PARSE 
               RPC_ERR_REQ RPC_ERR_METHOD RPC_ERR_PARAMS RPC_ERR_INTERNAL 
               RPC_ERR_SERVER RPC_SRV_ERR_MAX RPC_SRV_ERR_MIN 
               RPC_ERR_APP XAS_QUEUE START STOP EXIT 
               RELOAD STAT RUNNING ALIVE DEAD STOPPED STARTED RELOADED 
               STATED EXITED SHUTDOWN KILLME PROC_ROOT NOCMD
               LOG_LEVELS LOG_TYPES LOG_FACILITY ALERT_PRIORITY ALERT_FACILITY/,
      any => q/RPC_JSON RPC_DEFAULT_PORT RPC_DEFAULT_ADDRESS RPC_ERR_PARSE 
               RPC_ERR_REQ RPC_ERR_METHOD RPC_ERR_PARAMS RPC_ERR_INTERNAL 
               RPC_ERR_SERVER RPC_SRV_ERR_MAX RPC_SRV_ERR_MIN 
               RPC_ERR_APP XAS_QUEUE START STOP EXIT 
               RELOAD STAT RUNNING ALIVE DEAD STOPPED STARTED RELOADED 
               STATED EXITED SHUTDOWN KILLME PROC_ROOT NOCMD
               LOG_LEVELS LOG_TYPES LOG_FACILITY ALERT_PRIORITY ALERT_FACILITY/,
      tags => {
          jsonrpc => q/RPC_JSON RPC_DEFAULT_PORT RPC_DEFAULT_ADDRESS RPC_ERR_PARSE 
                      RPC_ERR_REQ RPC_ERR_METHOD RPC_ERR_PARAMS RPC_ERR_INTERNAL 
                      RPC_ERR_SERVER RPC_SRV_ERR_MAX RPC_SRV_ERR_MIN RPC_ERR_APP/,
          supervisor => q/START STOP EXIT RELOAD STAT RUNNING ALIVE DEAD 
                          STOPPED STARTED RELOADED STATED EXITED SHUTDOWN 
                          KILLME PROC_ROOT NOCMD/,
          logging => q/LOG_LEVELS LOG_TYPES LOG_FACILITY/,
          alerts  => q/ALERT_PRIORITY ALERT_FACILITY/,

      }
  }
;

1;

__END__

=head1 NAME

XAS::Constants - A Perl extension for the XAS environment

=head1 SYNOPSIS

 use XAS::Class
     base => 'XAS::Base',
     constant => 'TRUE FALSE'
 ;

 ... or ...

 use XAS::Constants 'TRUE FALSE';

=head1 DESCRIPTION

This module provides various constants for the XAS enviromnet. It inherits from
L<Badger::Constants|http://badgerpower.com/docs/Badger/Constants.html> and also provides these additional
constants.

=head2 EXPORT

 RPC_JSON RPC_DEFAULT_PORT RPC_DEFAULT_ADDRESS RPC_ERR_PARSE 
 RPC_ERR_REQ RPC_ERR_METHOD RPC_ERR_PARAMS RPC_ERR_INTERNAL 
 RPC_ERR_SERVER RPC_SRV_ERR_MAX RPC_SRV_ERR_MIN RPC_ERR_APP 

 LOG_TYPES LOG_FACILITY LOG_LEVELS

 ALERT_PRIORITY ALERT_FACILITY
 
 Along with these tags

 jsonrpc
 supervisor
 logging
 alerts
 
=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See L<http://dev.perl.org/licenses/> for more information.

=cut
