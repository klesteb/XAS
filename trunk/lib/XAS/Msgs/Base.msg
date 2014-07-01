#
# File: Base.msg
# Date: 30-Jun-2014
# By  : Kevin L. Esteb
#
# These are the messages for XAS base modules.
#

[messages]
messages_loaded   = don't remove this...
exception         = %s: %s
invparams         = invalid parameters passed, reason: %s
invmethod         = invalid method "%s", unable to auto load
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
badini            = unable to load config file: %s
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
connection        = unable to connect to %s on port %s
network           = a network communication error has occured, reason: %s
connection_failed = %s: the client connection failed with: %s, reason: %s
client_error      = %s: the client experienced error: %s, reason: %s
client_connect    = %s: a connection from %s on port %s
client_disconnect = %s: client disconnected from %s on port %s
nowheel           = %s: no wheel defined for output
recmsg            = %s: received message \"%s\" from %s on port %s
reaper            = %s: reaper invoked for %s on port %s
conerr            = unable to connect: %s, reason - %s
autherr           = unable to authenticate: %s, reason - %s
protoerr          = unexpected protocol error: %s, reason - %s
badval            = invalid header value
badkey            = invalid header key
noid              => v%s requires an id
nosub             => v%s requires a subscription
noque             => v%s requires a destination
nosup             => v%s doesn't support this frame type: %s
nopar             => you have invalid paramters for v%s"
