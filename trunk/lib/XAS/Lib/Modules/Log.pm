package XAS::Lib::Modules::Log;

our $VERSION = '0.01';

our ($types, $levels, $mixins);

BEGIN {
    $types  = qr/console|file|logstash|syslog/;
    $levels = qr/info|warn|error|fatal|debug|trace/;
    $mixins = {
        console  => 'XAS::Lib::Modules::Log::Console',
        file     => 'XAS::Lib::Modules::Log::File',
        logstash => 'XAS::Lib::Modules::Log::Logstash',
        syslog   => 'XAS::Lib::Modules::Log::Syslog',
    };
}

use DateTime;
use Params::Validate 'HASHREF';

use XAS::Class
  version    => $VERSION,
  base       => 'XAS::Hub Badger::Prototype',
  filesystem => 'File',
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
      -facility => { optional => 1, default => 'local7' },
      -levels   => { optional => 1, default => {}, type => HASHREF },
      -type     => { optional => 1, default => 'console', regex => $types },
    }
  },
  messages  => {
    bad_level => 'invalid logging level: %s',
  }
;

#use Data::Dumper;

# ------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------

sub level {
    my $self  = shift;

    $self = $self->prototype() unless ref $self;

    my ($level, $action) = $self->validate_params(\@_, [
        { regex => $levels },
        { optional => 1, default => undef , regex => qr/0|1/ },
    ]);

    $self->{$level} = $action if (defined($action));

    return $self->{$level};

}

sub build {
    my $self = shift;

    $self = $self->prototype() unless ref $self;

    my ($level, $message) = $self->validate_params(\@_, [1,1]);

    return {
        hostname => $self->env->host,
        datetime => DateTime->now(time_zone => 'local'),
        process  => $self->process,
        pid      => $$,
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

    # populate $self for each level using the 
    # value in $self->levels, or the default in $LEVELS

    my $l = $self->class->hash_vars( LEVELS => $self->levels );

    while (my ($level, $default) = each %$l) {

        $self->level($level, $default);

    }

    # load and initialize our output mixin

    $self->class->mixin($mixins->{$type});
    $self->init_log();

    return $self;

}

sub DESTROY {
    my $self = shift;
    
    $self->destroy();
    
}

# ------------------------------------------------------------------------
# autogenerate some methods, saves typing
# ------------------------------------------------------------------------

foreach my $level (keys %$LEVELS) {

    no strict "refs";                 # to register new methods in package
    no warnings;                      # turn off warnings

    *$level = sub {
        my $self = shift;

        $self = $self->prototype() unless ref $self;

        return $self->{$level} unless @_;

        if ($self->{$level}) {

            my $args = $self->build("$level", join(" ", @_));
            $self->output($args);

        }

    };

    *$level . '_msg' => sub {
        my $self = shift;

        $self = $self->prototype() unless ref $self;

        return $self->{$level} unless @_;

        if ($self->{$level}) {

            my $args = $self->build("$level", $self->message(@_));
            $self->output($args);

        }

    };

}

1;

__END__

=head1 NAME

XAS::Lib::Modules::Log - log for errors, warnings and other messages

=head1 SYNOPSIS

    use Badger::Log;
    
    my $log = Badger::Log->new({
        debug => 0,      # ignore debug messages
        info  => 1,      # print info messages
        warn  => \@warn, # add warnings to list
        error => $log2,  # delegate errors to $log2
        fatal => sub {   # custom fatal error handler
            my $message = shift;
            print "FATAL ERROR: $message\n";
        },
    });
        
    $log->debug('a debug message');
    $log->info('an info message');
    $log->warn('a warning message');
    $log->error('an error message');
    $log->fatal('a fatal error message');

=head1 DESCRIPTION

This module defines a simple base class module for logging messages
generated by an application.  It is intentionally very simple in design,
providing the bare minimum in functionality with the possibility for
extension by subclassing.  

It offers little, if anything, over the many other fine logging modules 
available from CPAN.  It exists to provide a basic logging facility 
that integrates cleanly with, and can be bundled up with the other Badger 
modules so that you've got something that works "out of the box".

There are five message categories:

=over

=item debug

A debugging message.  

=item info

A message providing some general information.

=item warn

A warning message.

=item error

An error message.

=item fatal

A fatal error message.

=back

=head1 CONFIGURATION OPTIONS

=head2 debug

Flag to indicate if debugging messages should be generated and output.
The default value is C<0>.  It can be set to C<1> to enable debugging
messages or to one of the other reference values described in the 
documentation for the L<new()> method.

=head2 info

Flag to indicate if information messages should be generated and output.
The default value is C<0>.  It can be set to C<1> to enable information
messages or to one of the other reference values described in the 
documentation for the L<new()> method.

=head2 warn

Flag to indicate if warning messages should be generated and output.
The default value is C<1>.  It can be set to C<0> to disable warning
messages or to one of the other reference values described in the 
documentation for the L<new()> method.

=head2 error

Flag to indicate if error messages should be generated and output.
The default value is C<1>. It can be set to C<0> to disable error 
messages or to one of the other reference values described in the 
documentation for the L<new()> method.

=head2 fatal

Flag to indicate if fatal messages should be generated and output. The default
value is C<1>. It can be set to C<0> to disable fatal error messages (at your
own peril) or to one of the other reference values described in the
documentation for the L<new()> method.

=head2 format

This option can be used to define a different log message format.  

    my $log = Badger::Log->new(
        format => '[<level>] [<time>] <message>',
    );

The default message format is:

    [<time>] [<system>] [<level>] <message>

The C<E<lt>XXXE<gt>> snippets are replaced with their equivalent values:

    time        The current local time
    system      A system identifier, defaults to 'Badger'
    level       The message level: debug, info, warn, error or fatal
    message     The log message itself

The format can also be set using a C<$FORMAT> package variable in a subclass
of C<Badger::Log>.

    package Your::Log::Module;
    use base 'Badger::Log';
    our $FORMAT = '[<level>] [<time>] <message>';
    1;

=head2 system

A system identifier which is inserted into each message via the
C<E<lt>systemE<gt>> snippet.  See L<format> for further information.
The default value is C<Badger>.

    my $log = Badger::Log->new(
        system => 'MyApp',
    );

The system identifier can also be set using a C<$SYSTEM> package variable in a
subclass of C<Badger::Log>.

    package Your::Log::Module;
    use base 'Badger::Log';
    our $SYSTEM = 'MyApp';
    1;

=head1 METHODS

=head2 new(\%options)

Constructor method which creates a new C<Badger::Log> object.  It
accepts a list of named parameters or reference to hash of
configuration options that define how each message type should be
handled.

    my $log = Badger::Log->new({
        debug => 0,      # ignore debug messages
        info  => 1,      # print info messages
        warn  => \@warn, # add warnings to list
        error => $log2,  # delegate errors to $log2
        fatal => sub {   # custom fatal error handler
            my $message = shift;
            print "FATAL ERROR: $message\n";
        },
    });

Each message type can be set to C<0> to ignore messages or C<1> to
have them printed to C<STDERR>.  They can also be set to reference a list
(the message is appended to the list), a subroutine (which is called,
passing the message as an argument), or any object which implements a 
L<log()> method (to which the message is delegated).

=head2 debug($message)

Generate a debugging message.

    $log->debug('The cat sat on the mat');

=head2 info($message)

Generate an information message.

    $log->info('The pod doors are closed');

=head2 warn($message)

Generate a warning message.

    $log->warn('The pod doors are opening');

=head2 error($message)

Generate an error message.

    $log->error("I'm sorry Dave, I can't do that');

=head2 fatal($message)

Generate a fatal error message.

    $log->fatal('HAL is dead, aborting mission');

=head2 debug_msg($format,@args)

This method uses the L<message()|Badger::Base/message()> method inherited
from L<Badger::Base> to generate a debugging message from the arguments
provided.  To use this facility you first need to create your own logging
subclass which defines the message formats that you want to use.

    package Your::Log;
    use base 'Badger::Log';
    
    our $MESSAGES = {
        denied => "Denied attempt by %s to %s",
    };
    
    1;

You can now use your logging module like so:

    use Your::Log;
    my $log = Your::Log->new;
    
    $log->debug_msg( denied => 'Arthur', 'make tea' );

The log message generated will look something like this:

# TODO

=head2 info_msg($format,@args)

This method uses the L<message()|Badger::Base/message()> method inherited
from L<Badger::Base> to generate an info message from the arguments
provided.  See L<debug_msg()> for an example of using message formats.

=head2 warn_msg($format,@args)

This method uses the L<message()|Badger::Base/message()> method inherited
from L<Badger::Base> to generate a warning message from the arguments
provided.  See L<debug_msg()> for an example of using message formats.

=head2 error_msg($format,@args)

This method uses the L<message()|Badger::Base/message()> method inherited
from L<Badger::Base> to generate an error message from the arguments
provided.  See L<debug_msg()> for an example of using message formats.

=head2 fatal_msg($format,@args)

This method uses the L<message()|Badger::Base/message()> method inherited
from L<Badger::Base> to generate a fatal error message from the arguments
provided.  See L<debug_msg()> for an example of using message formats.

=head2 log($level, $message) 

This is the general-purpose logging method that the above methods call.

    $log->log( info => 'star child is here' );

=head2 level($level, $action)

This method is used to get or set the action for a particular level.
When called with a single argument, it returns the current action 
for that level.

    my $debug = $log->level('debug');

When called with two arguments it sets the action for the log level 
to the second argument.

    $log->level( debug => 0 );      # disable
    $log->level( info  => 1 );      # enable
    $log->level( warn  => $list );  # push to list
    $log->level( error => $code );  # call code
    $log->level( fatal => $log2 );  # delegate to another log

=head2 enable($level)

This method can be used to enable one or more logging levels.

    $log->enable('debug', 'info', 'warn');

=head2 disable($level)

This method can be used to disable one or more logging levels.

    $log->disable('error', 'fatal');

=head1 INTERNAL METHODS

=head2 _error_msg($format,@args)

The L<error_msg()> method redefines the L<error_msg()|Badger::Base/error_msg()>
method inherited from L<Badger::Base> (which can be considered both a bug and
a feature).  The internal C<_error_msg()> method effectively bypasses the 
new method and performs the same functionality as the base class method, in 
throwing an error as an exception.

=head2 _fatal_msg($format,@args)

As per L<_error_msg()>, this method provides access to the functionality
of the L<fatal_msg()|Badger::Base/fatal_msg()> method in L<Badger::Base>.

=head1 AUTHOR

Andy Wardley L<http://wardley.org/>

=head1 COPYRIGHT

Copyright (C) 2005-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Badger::Log::File>

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:



