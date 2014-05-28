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
      
      LOG_LEVELS => qr/info|warn|error|fatal|debug|trace/,
      LOG_TYPES  => qr/console|file|logstash|syslog/,
  },
  exports => {
      all => q/RPC_JSON RPC_DEFAULT_PORT RPC_DEFAULT_ADDRESS RPC_ERR_PARSE 
               RPC_ERR_REQ RPC_ERR_METHOD RPC_ERR_PARAMS RPC_ERR_INTERNAL 
               RPC_ERR_SERVER RPC_SRV_ERR_MAX RPC_SRV_ERR_MIN 
               RPC_ERR_APP XAS_QUEUE START STOP EXIT 
               RELOAD STAT RUNNING ALIVE DEAD STOPPED STARTED RELOADED 
               STATED EXITED SHUTDOWN KILLME PROC_ROOT NOCMD/,
      any => q/RPC_JSON RPC_DEFAULT_PORT RPC_DEFAULT_ADDRESS RPC_ERR_PARSE 
               RPC_ERR_REQ RPC_ERR_METHOD RPC_ERR_PARAMS RPC_ERR_INTERNAL 
               RPC_ERR_SERVER RPC_SRV_ERR_MAX RPC_SRV_ERR_MIN 
               RPC_ERR_APP XAS_QUEUE START STOP EXIT 
               RELOAD STAT RUNNING ALIVE DEAD STOPPED STARTED RELOADED 
               STATED EXITED SHUTDOWN KILLME PROC_ROOT NOCMD/,
      tags => {
          jsonrpc => q/RPC_JSON RPC_DEFAULT_PORT RPC_DEFAULT_ADDRESS RPC_ERR_PARSE 
                      RPC_ERR_REQ RPC_ERR_METHOD RPC_ERR_PARAMS RPC_ERR_INTERNAL 
                      RPC_ERR_SERVER RPC_SRV_ERR_MAX RPC_SRV_ERR_MIN RPC_ERR_APP/,
          supervisor => q/START STOP EXIT RELOAD STAT RUNNING ALIVE DEAD 
                          STOPPED STARTED RELOADED STATED EXITED SHUTDOWN 
                          KILLME PROC_ROOT NOCMD/,
          logging => q/LOG_LEVELS LOG_TYPES/,

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
L<Badger::Constants|Badger::Constants> and also provides those constants.

=head2 EXPORT

 AVAILABLE DELETE UNKNOWN QUEUED COMPLETED EXITING RUNNING 
 MOVING WAITING SUSPENDED SUBMIT SUBMITTED JOBSTATS RPC_JSON 
 RPC_DEFAULT_PORT RPC_DEFAULT_ADDRESS RPC_ERR_PARSE RPC_ERR_REQ 
 RPC_ERR_METHOD RPC_ERR_PARAMS RPC_ERR_INTERNAL RPC_ERR_SERVER 
 RPC_SRV_ERR_MAX RPC_SRV_ERR_MIN RPC_ERR_APP LABEL_F1 LABEL_F2 
 LABEL_F3 LABEL_F4 LABEL_F5 LABEL_F6 LABEL_F7 LABEL_F8 LABEL_F9 
 LABEL_F10 LABEL_F11 LABEL_F12 START STOP EXIT RELOAD STAT 
 RUNNING ALIVE DEAD STOPPED STARTED RELOADED STATED EXITED 
 SHUTDOWN KILLME PROC_ROOT

 Along with these tags

 batch
 workman
 jsonrpc
 labels
 supervisor

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
