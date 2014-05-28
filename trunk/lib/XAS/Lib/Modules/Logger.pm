package XAS::Lib::Modules::Logger;

my ($types, $levels);

our $VERSION = '0.01';

BEGIN {
    $types  = qr/console|file|json|syslog/i;
    $levels = qr/info|warn|error|fatal|debug|trace/i;
}

use Try::Tiny;
use Badger::Filesystem 'File';

use XAS::Class
  debug    => 0,
  version  => $VERSION,
  base     => 'XAS::Base Badger::Prototype',
  mutators => 'category',
  vars => {
    PARAMS => {
      -type     => { optional => 1, default => 'console', regex => $types },
      -filename => { optional => 1, isa => 'Badger::Filesystem::File', default => File('stderr') },
    }
  }
;

#use Data::Dumper;

# ------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------

for my $routine (qw( info warn error fatal debug trace )) {

    no strict "refs";                 # to register new methods in package
    no warnings;                      # turn off warnings

    *$routine = sub {
        my $self = shift;

        $self = $self->prototype() unless ref $self;

        my ($text) = $self->validate_params(\@_, [1]);
        

    }

    *"$routine_msg" = sub {
        my $self = shift;

        $self = $self->prototype() unless ref $self;

        my ($message, $text) = $self->validate_params(\@_, [1, 1]);


    }

}

sub level {
    my $self = shift;

    $self = $self->prototype() unless ref $self;

    my ($level) = $self->validate_params(\@_, [
        { optional => 1, default => undef, regex => $levels }
    ]);

    my $old_level = 0;
    my $category = $self->category();
    my $logger   = get_logger($category);

    if (defined($level)) {

        my $new_level = $self->_convert_to_level($level);
        $old_level = $logger->level($new_level);

    } else {

        $old_level = $logger->level();

    }

    return $self->_convert_from_level($old_level);

}

# ------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------

sub _convert_to_level {
    my $self  = shift;
    my $level = shift;

    return $WARN  if ($level =~ /warn/i);
    return $ERROR if ($level =~ /error/i);
    return $FATAL if ($level =~ /fatal/i);
    return $DEBUG if ($level =~ /debug/i);
    return $INFO;

}

sub _convert_from_level {
    my $self  = shift;
    my $level = shift;

    return 'warn'  if ($level == $WARN);
    return 'error' if ($level == $ERROR);
    return 'fatal' if ($level == $FATAL);
    return 'debug' if ($level == $DEBUG);
    return 'info'

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    my $logcfg  = $self->configs;
    my $logfile = $self->filename->path;

    # Diddling with the symbol table.
    #
    # In the log file defination below, this line:
    #
    # log4perl.appender.logfile.filename = sub { _get_logfile(); }
    #
    # causes Log4perl to do a callback to main::_get_logfile(). This
    # callback returns the filename of the log file, 

    {
        no warnings;
        *main::_get_logfile = sub { $logfile; }
    }

    unless (defined($logcfg)) {

        # Retrieve the default log defination.

        if ($logfile =~ /stderr/i) {

            $logcfg = q(
                log4perl.rootLogger = INFO, screen
                log4perl.appender.screen = Log::Log4perl::Appender::Screen
                log4perl.appender.screen.stderr = 1
                log4perl.appender.screen.layout = PatternLayout
                log4perl.appender.screen.layout.ConversionPattern = %-5p - %m%n
            );

        } else {

            # If the name is not stderr, define a log file defination
            # this is based on OS type. When setting the umask on Win32
            # you get a read only file...
            
            if ($^O eq 'MSWin32') {

                $logcfg = q(
                    log4perl.rootLogger = INFO, logfile
                    log4perl.appender.logfile = Log::Log4perl::Appender::File
                    log4perl.appender.logfile.filename = sub { _get_logfile(); }
                    log4perl.appender.logfile.mode = append
                    log4perl.appender.logfile.syswrite = 1
                    log4perl.appender.logfile.layout = PatternLayout
                    log4perl.appender.logfile.layout.ConversionPattern = [%d{yyyy-MM-dd HH:mm:ss}] %-5p - %m%n
                );

            } else {

                # File protection mask will be -rw-rw-r--

                $logcfg = q(
                    log4perl.rootLogger = INFO, logfile
                    log4perl.appender.logfile = Log::Log4perl::Appender::File
                    log4perl.appender.logfile.filename = sub { _get_logfile(); }
                    log4perl.appender.logfile.mode = append
                    log4perl.appender.logfile.umask = 0002
                    log4perl.appender.logfile.syswrite = 1
                    log4perl.appender.logfile.layout = PatternLayout
                    log4perl.appender.logfile.layout.ConversionPattern = [%d{yyyy-MM-dd HH:mm:ss}] %-5p - %m%n
                );

            }

        }

        Log::Log4perl->init(\$logcfg);

    } else {

        # Or specify something else, notice we are not putting any semantics
        # on this value. So it could be anything acceptable to Log4perl.
        # This is assuming a file name of some sort.

        Log::Log4perl->init($logcfg);

    }

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::System::Logger - The logger module for the XAS environment

=head1 SYNOPSIS

Your program can use this module in the following fashion:

 use XAS::Lib::System::Logger;

 my $log = XAS::Lib::System::Logger->new();;

 $log->info('this is a test');

and this will print:

 INFO  - this is a test

to stderr.

=head1 DESCRIPTION

This is the module for writing log events to a log file.

=head1 METHODS

=head2 new

This method initializes the module. It takes these parameters:

=over 4

=item B<-filename>

The name of the log file. This needs to be a Badger::Filesystem::File object.

=item B<-configs>

An optional Log::Log4perl configuration file.

=back

=head2 info($message)

This method will write a INFO line into the log.

=over 4

=item B<$message>

The message to write.

=back

=head2 warn($message)

This method will write a WARN line into the log.

=over 4

=item B<$message>

The message to write.

=back

=head2 error($message)

This method will write a ERROR line into the log.

=over 4

=item B<$message>

The message to write.

=back

=head2 fatal($message)

This method will write a FATAL line into the log.

=over 4

=item B<$message>

The message to write.

=back

=head2 debug($message)

This method will write a DEBUG line into the log.

=over 4

=item B<$message>

The message to write.

=back

=head2 trace($message)

This method will write a TRACE line into the log.

=over 4

=item B<$message>

The message to write.

=back

=head2 level($level)

This method will set the current logging level. The following levels are used:

 info, warn, error, fatal, debug, trace

=head2 category($category)

Set the catecory for the logger. 

=over 4

=item B<$category>

A text string with meaning for the logger.

=back

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
