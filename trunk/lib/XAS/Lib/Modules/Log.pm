package XAS::Lib::Modules::Log;

our $VERSION = '0.02';

use DateTime;
use XAS::Constants ':logging';
use Params::Validate 'HASHREF';

use XAS::Class
  version    => $VERSION,
  base       => 'XAS::Singleton',
  filesystem => 'File',
  utils      => ':boolean',
  vars => {
    LEVELS => {
      trace => 0,
      debug => 0,
      info  => 1,
      warn  => 1,
      error => 1,
      fatal => 1,
    },
    PARAMS => {
      -filename => { optional => 1 },
      -process  => { optional => 1, default => 'XAS' },
      -levels   => { optional => 1, default => {}, type => HASHREF },
      -facility => { optional => 1, default => undef, regex => LOG_FACILITY },
      -type     => { optional => 1, default => 'console', regex => LOG_TYPES },
    }
  },
;

#use Data::Dumper;

my $mixins = {
    console => 'XAS::Lib::Modules::Log::Console',
    file    => 'XAS::Lib::Modules::Log::File',
    json    => 'XAS::Lib::Modules::Log::Json',
    syslog  => 'XAS::Lib::Modules::Log::Syslog',
};

# ------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------

sub level {
    my $self  = shift;
    my ($level, $action) = $self->validate_params(\@_, [
        { regex => LOG_LEVELS },
        { optional => 1, default => undef , 
          callbacks => {
              'must be a boolean value or undef' => sub {
                  my $param = shift;
                  return 1 unless (defined($param));
                  return 1 if (is_truthy($param));
                  return 1 if (is_falsey($param));
              }
          }
        },
    ]);

    $self->{$level} = $action if (defined($action));

    return $self->{$level};

}

sub build {
    my $self = shift;
    my ($level, $message) = $self->validate_params(\@_, [
        { regex => LOG_LEVELS },
        1
    ]);

    return {
        hostname => $self->env->host,
        datetime => DateTime->now(time_zone => 'local'),
        process  => $self->process,
        pid      => $$,
        msgid    => 0,
        facility => $self->facility,
        priority => $level,
        message  => $message,
    };

}

# ------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);
    my $type = $self->type();

    if (defined($self->{filename})) {

        $self->{filename} = File($self->{filename});

    }

    unless (defined($self->{facility})) {

        $self->{facility} = $self->env->log_facility;

    }

    # populate $self for each level using the 
    # value in $self->levels, or the default in $LEVELS

    my $l = $self->class->hash_vars( LEVELS => $self->levels );

    while (my ($level, $default) = each %$l) {

        $self->level($level, $default);

    }

    # autogenerate some methods, saves typing

    foreach my $level (keys %$LEVELS) {

        $self->class->methods($level => sub {
            my $self = shift;

            return $self->{$level} unless @_;

            if ($self->{$level}) {

                my $args = $self->build("$level", join(" ", @_));
                $self->output($args);

            }

        });

        $self->class->methods($level . '_msg' => sub {
            my $self = shift;

            return $self->{$level} unless @_;

            if ($self->{$level}) {

                my $args = $self->build("$level", $self->message(@_));
                $self->output($args);

            }

        });

    }

    # load and initialize our output mixin

    $self->class->mixin($mixins->{$type});
    $self->class->var('MESSAGES', $self->env->get_msgs);

    $self->init_log();

    return $self;

}

sub DESTROY {
    my $self = shift;

    $self->destroy() if ($self->can('destroy'));

}

1;

__END__

=head1 NAME

XAS::Lib::Modules::Log - A class for logging in the XAS Environment

=head1 SYNOPSIS

    use XAS::Lib::Modules::Log;

    my $log = XAS::Lib::Modules::Log->new();

    $log->debug('a debug message');
    $log->info('an info message');
    $log->warn('a warning message');
    $log->error('an error message');
    $log->fatal('a fatal error message');
    $log->trace('a tracing message');

=head1 DESCRIPTION

This module defines a simple logger for  messages
generated by an application.  It is intentionally very simple in design,
providing the bare minimum in functionality with the possibility for
extension by sub-classing.  

=head1 METHODS

=head2 new

This will initialize the base object. It takes the following parameters:

=over 4

=item B<-type>

The type of the log. This can be "console", "file", "json" or "syslog".
Defaults to "console". Which means all logging goes to the current terminal.

=item B<-filename>

The name of the log file. This only is relevant if the log type is "file".

=item B<-facility>

The facility of the log message. Primarily has meaning when using a log type of
"json" or "syslog". The following have been defined and follows the syslog
standard.
 
    auth, authpriv, cron, daemon, ftp,
    local[0-7], lpr, mail, news, user, uucp

Defaults to "local6".

=item B<-process>

The name of the process. Defaults to "XAS", which is not to useful.

=item B<-levels>

A hashref of values to set the internal logging level with.

Example:

    my $log = XAS::Lib::Modules::Log->new(
        -levels => {
            debug => $self->debugging ? 1 : 0,
        }
    );

This would set the debug level of logging, depending on the value of
$self->debugging.

=back

=head2 level($level, $boolean)

This will query or toggle the log level. When toggled that particular level is set.
There is no hierarchy of log levels.

=over 4

=item B<$level>

The log level to toggle. This can be one of the following:

 info, warn, error, fatal, debug, trace

=item B<$boolean>

An optional valve. It needs to be 0 or 1 to set the level.

=back

=head2 info($line)

This method will log an entry with an level of "info".

=over 4

=item B<$line>

The message to write out. This can be an array which will be joined with a
"space" separator.

=back

=head2 warn($line)

This method will log an entry with an level of "warn".

=over 4

=item B<$line>

The message to write out. This can be an array which will be joined with a
"space" separator.

=back

=head2 error($line)

This method will log an entry with an level of "error".

=over 4

=item B<$line>

The message to write out. This can be an array which will be joined with a
"space" separator.

=back

=head2 fatal($line)

This method will log an entry with an level of "fatal".

=over 4

=item B<$line>

The message to write out. This can be an array which will be joined with a
"space" separator.

=back

=head2 debug($line)

This method will log an entry with an level of "debug". By default this level
is turned off.

=over 4

=item B<$line>

The message to write out. This can be an array which will be joined with a
"space" separator.

=back

=head2 trace($line)

This method will log an entry with an level of "trace".

=over 4

=item B<$line>

The line to write out. This can be an array which will be joined with a
"space" separator.

=back

=head2 info_msg($message, $line)

This method will log an entry with an level of "info". 

=over 4

=item B<$message>

The message to apply line against. This should be defined in the package
variable $MESSAGE or in the message stanza in XAS::Class.

=item B<$line>

The line to write out. This can be an array which will be joined with a
"space" separator.

=back

=head2 warn_msg($message, $line)

This method will log an entry with an level of "warn". 

=over 4

=item B<$message>

The message to apply line against. This should be defined in the package
variable $MESSAGE or in the message stanza in XAS::Class.

=item B<$line>

The line to write out. This can be an array which will be joined with a
"space" separator.

=back

=head2 error_msg($message, $line)

This method will log an entry with an level of "error". 

=over 4

=item B<$message>

The message to apply line against. This should be defined in the package
variable $MESSAGE or in the message stanza in XAS::Class.

=item B<$line>

The line to write out. This can be an array which will be joined with a
"space" separator.

=back

=head2 fatal_msg($message, $line)

This method will log an entry with an level of "fatal". 

=over 4

=item B<$message>

The message to apply line against. This should be defined in the package
variable $MESSAGE or in the message stanza in XAS::Class.

=item B<$line>

The line to write out. This can be an array which will be joined with a
"space" separator.

=back

=head2 debug_msg($message, $line)

This method will log an entry with an level of "debug". 

=over 4

=item B<$message>

The message to apply line against. This should be defined in the package
variable $MESSAGE or in the message stanza in XAS::Class.

=item B<$line>

The line to write out. This can be an array which will be joined with a
"space" separator.

=back

=head2 trace_msg($message, $line)

This method will log an entry with an level of "trace". 

=over 4

=item B<$message>

The message to apply line against. This should be defined in the package
variable $MESSAGE or in the message stanza in XAS::Class.

=item B<$line>

The line to write out. This can be an array which will be joined with a
"space" separator.

=back

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
