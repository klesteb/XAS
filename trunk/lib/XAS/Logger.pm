package WPM::System::Logger;

our $VERSION = '0.01';

use DateTime;
use Data::Dumper;

use WPM::Class
    version    => 0.01,
    base       => 'Badger::Prototype',
    import     => 'class',
    utils      => 'blessed',
    config     => 'system|class:SYSTEM format|class:FORMAT filename',
    filesystem => 'File',
    constants  => 'ARRAY CODE',
    constant => {
        MSG => '_msg',        # suffix for message methods, e.g. warn_msg()
        LOG => 'log',         # method a delegate must implement
    },
    vars => {
        SYSTEM => 'WPM',
        FORMAT => "[<time>] <level> - <message>",
        LEVELS => {
            debug => 0,
            info  => 1,
            warn  => 1,
            error => 1,
            fatal => 1,
        }
    },
    messages => {
        bad_level => 'invalid logging level: %s',
        invperms  => "unable to change file permissions on %s",
        creatfile => "unable to create file %s"
    }
;

class->methods(
    # Our init method is called init_log() so that we can use Badger::Log as
    # a mixin or base class without worrying about the init() method clashing
    # with init() methods from other base classes or mixins.  We create an
    # alias from init() to init_log() so that it also Just Works[tm] as a
    # stand-alone object
    init   => \&init_log,

    # Now we define two methods for each logging level.  The first expects
    # a pre-formatted output message (e.g. debug(), info(), warn(), etc)
    # the second additionally wraps around the message() method inherited
    # from Badger::Base (eg. debug_msg(), info_msg(), warn_msg(), etc)
    map {
        my $level = $_;             # lexical variable for closure

        $level => sub {
            my $self = shift;
            return $self->{ $level } unless @_;
            $self->log($level, @_)
                if $self->{ $level };
        },

        ($level.MSG) => sub {
            my $self = shift;
            return $self->{ $level } unless @_;
            $self->log($level, $self->message(@_))
                if $self->{ $level };
        }
    }
    keys %$LEVELS
);

sub init_log {
    my ($self, $config) = @_;

    # strip leading '-' from config variables

    while (my ($key, $value) = each %$config) {

        delete $config->{$key};

        $key =~ s/^-//g;
        $config->{$key} = $value;

    }

    my $class  = $self->class;
    my $levels = $class->hash_vars( LEVELS => $config->{ levels } );

    # populate $self for each level in $LEVEL using the
    # value in $config, or the default in $LEVEL

    while (my ($level, $default) = each %$levels) {
        $self->{ $level } =
            defined $config->{ $level }
                  ? $config->{ $level }
                  : $levels->{ $level };
    }

    # call the auto-generated configure() method to update $self from $config

    $self->configure($config);

    # make a Badger::Filesystem::File object.

    $self->{filename} = File($self->{filename}) unless (ref($self->{filename}));

    # if a filename exists, initialize the file and redirect to it

    if ((my $filename = $self->{filename}->path) and ($self->{filename}->name !~ /^stderr$/i )) {

        # check to see if file exists, otherwise create it

        unless ( -e $filename ) {

            if (my $fh = $self->{filename}->open('>')) {

                $fh->close;

            } else {

                $self->_error_msg('creatfile', $filename);

            }

        }

        if ($^O ne "MSWin32") {

            my ($cnt, $mode, $permissions);

            # set file permissions

            $mode = (stat($filename))[2];
            $permissions = sprintf("%04o", $mode & 07777);

            if ($permissions ne "0664") {

                $cnt = chmod(0664, $filename);
                $self->_error_msg('invperms', $filename) if ($cnt < 1);

            }

        }

   }

    return $self;

}

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub format {
    my $self = shift;

    my $dt = DateTime->now(time_zone => 'local');
    my $args = {
      time    => sprintf("%s %s", $dt->ymd('-'), $dt->hms),
      system  => $self->{system},
      level   => sprintf("%-5s", uc(shift)),
      message => shift,
    };

    my $format = $self->{format};

    $format =~
        s/<(\w+)>/
        defined $args->{ $1 }
            ? $args->{ $1 }
            : "<$1>"
            /eg;

    return $format;

}

sub level {
    my $self  = shift;
    my $level = shift;
    return $self->_fatal_msg( bad_level => $level )
        unless exists $LEVELS->{ $level };
    return @_ ? ($self->{ $level } = shift) : $self->{ $level };
}

sub enable {
    my $self = shift;
    $self->level($_ => 1) for @_;
}

sub disable {
    my $self = shift;
    $self->level($_ => 0) for @_;
}

sub log {
    my $self    = shift;
    my $level   = shift;
    my $action  = $self->{ $level };
    my $message = join('', @_);
    my $method;

    return $self->_fatal_msg( bad_level => $level )
        unless defined $action;

    # depending on what the $action is set to, we add the message to
    # an array, call a code reference, delegate to another log object,
    # print or ignore the mesage

    if (ref $action eq ARRAY) {

        push(@$action, $message);

    } elsif (ref $action eq CODE) {

        &$action($level, $message);

    } elsif (blessed $action && ($method = $action->can(LOG))) {

        $method->($action, $level, $message);

    } elsif ($action) {

        if ($self->{filename}->name eq 'stderr') {

            warn $self->format($level, $message) . "\n";

        } else {

           $self->{filename}->append($self->format($level, $message) . "\n");

        }

    }

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _error_msg {
    my $self = shift;
    $self->Badger::Base::error(
        $self->Badger::Base::message(@_)
    );
}

sub _fatal_msg {
    my $self = shift;
    $self->Badger::Base::fatal(
        $self->Badger::Base::message(@_)
    );
}

1;

__END__

=head1 NAME

WPM::System::Logger - The logging module for the WPM environment

=head1 SYNOPSIS

Your program could use this module in the following fashion:

 use WPM::System;

 $log = WPM::System->module(
      logger => {
          -filename => 'test.log',
          -debug => TRUE,
      }
 );

 $log->info("Hello world!");

 or ...

 use WPM::System;

 $ddc = WPM::System->module('environment');
 $log = WPM::System->module(
      logger => {
          -filename => $ddc->logfile,
          -debug    => TRUE,
      }
 );

 $log->info("Hello world!");

 or ...

 $log = WPM::System->module('logger');

 $log->info("Hello world");

=head1 DESCRIPTION

This is the the module for logging within the WPM environment, it is a
wrapper around Badger::Log. You should read the documentation for that
module to learn all the options that are available.

This module provides an extension that allows all options to have
a leading dash. This is to be consistent with the rest of the WPM modules. It
will also set the correct file permissions on the log files so they can be
interchanged within the environment.

By default, the following log levels are active:

    info
    warn
    error
    fatal

By default, output will be sent to stderr.

=head1 ACCESSORS

=head2 filename

This accessor will return the name of the current log file.

Example

     $filename = $log->filename;

=head1 SEE ALSO

 Badger::Log
 WPM::System
 WPM::System::Alert
 WPM::System::Email
 WPM::System::Environment

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
