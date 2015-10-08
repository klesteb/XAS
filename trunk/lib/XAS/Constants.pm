package XAS::Constants;

our $VERSION = '0.03';

use Badger::Class
  debug   => 0,
  version => $VERSION,
  base    => 'Badger::Constants',    # grab the badger constants
  constant => {

      # generic

      LF => "\012",
      CR => "\015",

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
      LOG_TYPES    => qr/console|file|json|syslog/,
      LOG_FACILITY => qr/auth|authpriv|cron|daemon|ftp|local[0-7]|lpr|mail|news|user|uucp/,

      # alerts

      ALERT_PRIORITY => qr/low|medium|high|info/i,
      ALERT_FACILITY => qr/systems/i,

      # stomp

      STOMP_EOF    => "\000",
      STOMP_LEVELS => qr/1\.[0-2]/,
      STOMP_CNTRL  => qr((?:[[:cntrl:]])+),
      STOMP_HEADER => qr(([\w\-~]+)\s*:\s*(.*)),
      STOMP_EOL    => qr((\015\012?|\012\015?|\015|\012)),
      STOMP_BEOH   => qr((\015\012\000?|\012\015\000?|\015\000|\012\000)),
      STOMP_EOH    => qr((\015\012\015\012?|\012\015\012\015?|\015\015|\012\012)),

  },
  exports => {
      all => 'RPC_JSON RPC_DEFAULT_PORT RPC_DEFAULT_ADDRESS RPC_ERR_PARSE 
              RPC_ERR_REQ RPC_ERR_METHOD RPC_ERR_PARAMS RPC_ERR_INTERNAL 
              RPC_ERR_SERVER RPC_SRV_ERR_MAX RPC_SRV_ERR_MIN 
              RPC_ERR_APP XAS_QUEUE START STOP EXIT 
              RELOAD STAT RUNNING ALIVE DEAD STOPPED STARTED RELOADED 
              STATED EXITED SHUTDOWN KILLME PROC_ROOT NOCMD
              LOG_LEVELS LOG_TYPES LOG_FACILITY ALERT_PRIORITY ALERT_FACILITY
              STOMP_LEVELS  STOMP_EOF STOMP_CNTRL STOMP_HEADER STOMP_EOL 
              STOMP_BEOH STOMP_EOH LF CR',
      any => 'RPC_JSON RPC_DEFAULT_PORT RPC_DEFAULT_ADDRESS RPC_ERR_PARSE 
              RPC_ERR_REQ RPC_ERR_METHOD RPC_ERR_PARAMS RPC_ERR_INTERNAL 
              RPC_ERR_SERVER RPC_SRV_ERR_MAX RPC_SRV_ERR_MIN 
              RPC_ERR_APP XAS_QUEUE START STOP EXIT 
              RELOAD STAT RUNNING ALIVE DEAD STOPPED STARTED RELOADED 
              STATED EXITED SHUTDOWN KILLME PROC_ROOT NOCMD
              LOG_LEVELS LOG_TYPES LOG_FACILITY ALERT_PRIORITY ALERT_FACILITY
              STOMP_LEVELS  STOMP_EOF STOMP_CNTRL STOMP_HEADER STOMP_EOL 
              STOMP_BEOH STOMP_EOH LF CR',
      tags => {
          jsonrpc => 'RPC_JSON RPC_DEFAULT_PORT RPC_DEFAULT_ADDRESS RPC_ERR_PARSE 
                      RPC_ERR_REQ RPC_ERR_METHOD RPC_ERR_PARAMS RPC_ERR_INTERNAL 
                      RPC_ERR_SERVER RPC_SRV_ERR_MAX RPC_SRV_ERR_MIN RPC_ERR_APP',
          logging => 'LOG_LEVELS LOG_TYPES LOG_FACILITY',
          alerts  => 'ALERT_PRIORITY ALERT_FACILITY',
          stomp   => 'STOMP_LEVELS STOMP_EOF STOMP_CNTRL STOMP_HEADER 
                      STOMP_EOL STOMP_BEOH STOMP_EOH',
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
L<Badger::Constants|https://metacpan.org/pod/Badger::Constants> and also provides these additional
constants.

=head2 EXPORT

 RPC_JSON RPC_DEFAULT_PORT RPC_DEFAULT_ADDRESS RPC_ERR_PARSE 
 RPC_ERR_REQ RPC_ERR_METHOD RPC_ERR_PARAMS RPC_ERR_INTERNAL 
 RPC_ERR_SERVER RPC_SRV_ERR_MAX RPC_SRV_ERR_MIN RPC_ERR_APP 

 LOG_TYPES LOG_FACILITY LOG_LEVELS

 ALERT_PRIORITY ALERT_FACILITY
 
 STOMP_LEVELS STOMP_EOF STOMP_CNTRL STOMP_HEADER STOMP_EOL 
 STOMP_BEOH STOMP_EOH

 CR LF

 Along with these tags

 jsonrpc
 logging
 alerts
 stomp

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
