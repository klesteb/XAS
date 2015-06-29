#
# File: Base.msg
# Date: 30-Jun-2014
# By  : Kevin L. Esteb
#
# These are the messages for XAS base modules.
#

[messages]
messages_loaded   = don't remove this...
startup           = starting up
shutdown          = shutting down
exception         = %s: %s
invparams         = invalid parameters passed, reason: %s
invmethod         = invalid method: unable to auto load "%s" in package: %s, line: %s
badini            = unable to load config file: %s, reason: %s
nospooldir        = no spool directory defined
unknownos         = unknown OS: %s
unexpected        = unexpected error: %s
unknownerror      = unknown error: %s
undeliverable     = unable to send mail to %s; reason: %s
noserver          = unable to connect to %s; reason: %s
nodelivery        = unable to send message to %s; reason: %s
sequence          = unable to retrieve sequence number from %s
write_packet      = unable to write a packet to %s
read_packet       = unable to read a packet from %s
lock_error        = unable to acquire a lock on %s
invperms          = unable to change file permissions on %s
signaled          = %s: recieved signal %s
noservice         = unable to start service; reason: %s
paused            = the service is already paused
unpaused          = the service is not paused
noalias           = can not set session alias %s
noaliasdef        = no alias defined
runerr            = %s is already running: %d
piderr            = %s has left a pid file behind, exiting
wrterr            = unable to create pid file %s
installed         = The service was successfully installed.
removed           = The service was successfully deinstalled.
failed            = The service action "%s" failed; reason: %s.
connection        = unable to connect to %s on port %s, reason: %s
network           = a network communication error has occured, reason: %s
recmsg            = %s: received message \"%s\" from %s on port %s
conerr            = unable to connect: %s, reason - %s
autherr           = unable to authenticate: %s, reason - %s
protoerr          = unexpected protocol error: %s, reason - %s
badval            = invalid header value
badkey            = invalid header key
client_connection_failed = %s: the client connection failed with: %s, reason: %s
client_error      = %s: the client experienced error: %s, reason: %s
client_connect    = %s: a connection from %s on port %s
client_disconnect = %s: client disconnected from %s on port %s
client_nowheel    = %s: no wheel defined for output
client_reaper     = %s: reaper invoked for %s on port %s
client_nosocket   = %s: no socket for %s on %s
client_noport     = 'no port has been assigned'
server_connection_failed = %s: operation: %s; reason: %s - %s
server_error      = %s: operation: %s; reason: %s - %s
server_reconnect  = %s: reconnection attempts: %s, count: %s
server_attempts   = %s: attempting reconnection: %s, waiting: %s seconds
server_recycle    = %s: cycling reconnection attempts, but not shutting down...
server_shutdown   = %s: shutting down, to many reconnection attempts
json_rpc_method   = the rpc method "%s" is unknown
json_rpc_version  = this server supports only json-rpc version 2.0
json_rpc_format   = this json-rpc format is not supported
json_rpc_batch    = the usage of json-rpc batch mode is not supported
json_rpc_notify   = the usage of json-rpc notifications is not supported
curl              = curl error: %s, reason: %s
xml_error         = %s
xml_parser        = unable to parse the document
xml_validate      = unable to validate the document
rpc_jsonerr       = error code: %s, reason: %s, extended: %s
rpc_invid         = the returned id doesn't match the supplied id
rpc_errorapp      = %s
db_duplicates     = %s: duplicate key found for: %s
db_nocolumn       = %s: no such column for: %s
db_badsyntax      = %s: invalid input syntax for: %s
db_nullcolumn     = %s: null value in column for: %s
db_toolong        = %s: value to long for type: %s
db_open           = %s: unable to access database: %s; reason: %s
initialize        = %s: unable to initialize: %s; reason %s
connected         = %s: connected to %s on %s
subscribed        = %s: subscribed to %s
receipts          = %s: received a receipt %s
unsubscribed      = %s: unsubscribed from %s
errors            = %s: received an error %s, message: %s, reason: %s
unknowntype       = %s: unknown packet type: %s
unknown           = %s: %s
received          = %s: recieved message %s, type: "%s" from %s
noid              = v%s requires an id
nosub             = v%s requires a subscription
noque             = v%s requires a destination
nosup             = v%s doesn't support this frame type: %s
nopar             = you have invalid paramters for v%s
# process messages
process_started  = %s: started process %s
process_paused   = %s: paused process %s
process_stopped  = %s: stopped process %s
process_killed   = %s: killed process %s
process_exited   = %s: process %s exited with a %s
location         = %s: can not find absolution location of %s
no_autorestart   = %s: auto restart disabled
nomore_retries   = %s: no more retries
unknown_exitcode = %s: unknown exit code

