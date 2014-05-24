package XAS::Lib::App;

our $VERSION = '0.04';

use Try::Tiny;
use Pod::Usage;
use Hash::Merge;
use Getopt::Long;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  mixin     => 'XAS::Lib::Mixins::Handlers',
  import    => 'class CLASS',
  utils     => 'dotid',
  vars => {
    PARAMS => {
      -throws   => { optional => 1, default => 'changeme' },
      -facility => { optional => 1, default => 'systems' },
      -priority => { optional => 1, default => 'low' },
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub signal_handler {
    my $signal = shift;

    my $ex = WPM::Exception->new(
        type => 'xas.lib.app.signal_handler',
        info => 'process interrupted by signal ' . $signal
    );

    $ex->throw();

}

sub define_signals {
    my $self = shift;

    $SIG{'INT'}  = \&signal_handler;
    $SIG{'QUIT'} = \&signal_handler;

}

sub define_pidfile {
    my $self = shift;

}

sub define_daemon {
    my $self = shift;

}

sub run {
    my $self = shift;

    my $rc = 0;

    try {

        $self->main();

    } catch {

        my $ex = $_;

        $rc = $self->exit_handler($ex);

    };

    return $rc;

}

sub main {
    my $self = shift;

    $self->log->warn('You need to override main()');

}

sub options {
    my $self = shift;

    return {};

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    class->throws($self->throws);

    my $options = $self->options();
    my $defaults = $self->_default_options();

    $self->_parse_cmdline($defaults, $options);

    $self->define_signals();
    $self->define_daemon();
    $self->define_pidfile();

    return $self;

}

sub _default_options {
    my $self = shift;

    my $version = $self->CLASS->VERSION;
    my $script  = $self->class->any_var('SCRIPT');

    $self->{logcfg} = undef;

    return {
        'logcfg=s' => \$self->{logcfg},
        'alerts!'  => sub { $self->alerts($_[1]); },
        'debug'    => sub { $self->debugging(1); },
        'help|h|?' => sub { pod2usage(-verbose => 0, -exitstatus => 0); },
        'manual'   => sub { pod2usage(-verbose => 2, -exitstatus => 0); },
        'version'  => sub { printf("%s - v%s\n", $script, $version); exit 0; }
    };

}

sub _parse_cmdline {
    my ($self, $defaults, $optional) = @_;

    my $hm = Hash::Merge->new('RIGHT_PRECEDENT');
    my %options = %{ $hm->merge($defaults, $optional) };

    GetOptions(%options) or pod2usage(-verbose => 0, -exitstatus => 1);

}

1;

__END__

=head1 NAME

XAS::Lib::App - The base class to write procedures within the XAS environment

=head1 SYNOPSIS

 use XAS::Lib::App;

 my $app = XAS::Lib::App->new();

 $app->run();

=head1 DESCRIPTION

This module defines a base class for writing procedures. It provides a
logger, signal handling, options processing along with a exit handler.

=head1 METHODS

=head2 new

This method initilaizes the module. It inherits from XAS::Base and takes 
several additional parameters:

=over 4

=item B<-throws>

This changes the default error message from "changeme" to something useful.

=item B<-facility>

This will change the facility of the alert. The default is 'systems'.

=item B<-priority>

This will change the priority of the alert. The default is 'low'.

=back

=head2 run

This method sets up a global exception handler and calls main(). The main() 
method will be passed one parameter: an initialised handle to this class.

Example

    sub main {
        my $self = shift;

        $self->log->debug('in main');

    }

=over 4

=item Exception Handling

If an exception is caught, the global exception handler will send an alert, 
write the exception to the log and returns an exit code of 1. 

=item Normal Completiion

When the procedure completes successfully, it will return an exit code of 0. 

=back

To change this behavior you would need to override the exit_handler() method.

=head2 main

This is where your main line logic starts.

=head2 options

This method sets up additional cli options. Option handling is provided
by Getopt::Long. To access these options you need to define accessors for
them.

  Example

    use WPM::Class
      version    => '0.01',
      base       => 'WPM::Lib::App',
      filesystem => 'File',
      accessors  => 'logfile
    ;

    sub main {
        my $self = shift;

        $self->log('info', 'starting up');
        sleep(60);
        $self->log('info', 'shutting down');

    }

    sub options {
        my $self = shift;

        $self->{logfile} = $self->env->logfile;
        $self->class->var('LOGFILE', $self->logfile->path);

        return {
            'logfile=s' => sub {
                $self->{logfile} = File($_[1]);
                $self->class->var('LOGFILE', $self->logfile->path);
            }
        };

    }

By default, log output goes to 'stderr'. This sets up a '--logfile' option.
It defines the default as <XAS_ROOT>/var/log/<$0>.log and sets
the package variable LOGFILE to the stringified path. If the '--logfile' 
option is used, then it sets up the options handling to do the same thing 
with the supplied parameter.

=head2 define_logging

This method sets up the logger using Log::Log4perl. It uses the package
variable LOGFILE to determine how logging is provided. The provided
logging configuration can be overridden by using the --logcfg cli option.

=head2 define_signals

This method sets up basic signal handling. By default this is only for the INT 
and QUIT signals.

Example

    sub define_signals {
        my $self = shift;

        $SIG{INT}  = \&signal_handler;
        $SIG{QUIT} = \&singal_handler;

    }

=head2 define_pidfile

This is an entry point to define a pid file.

=head2 define_daemon

This is an entry point so the procedure can daemonize.

=head2 signal_handler($signal)

This method is a default signal handler. By default it throws an exception. 
It takes one parameter.

=over 4

=item B<$signal>

The signal that was captured.

=back

=head1 ACCESSORS

This module has several accessors that make life easier for you.

=head2 alert

This is the handle to the XAS Alert system.

=head2 env

This is the handle to the XAS environment.

=head2 alerts

Wither or not to send alerts.

=head1 OPTIONS

This module handles the following command line options.

=head2 --debug

This toggles debugging output.

=head2 --[no]alerts

This toggles sending alerts. They are on by default.

=head2 --help

This prints out a short help message based on the procedures pod.

=head2 --manual

This displaces the procedures manual in the defined pager.

=head2 --version

This prints out the version of the module.

=head2 --logcfg

An optional Log::Log4perl configuration file.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
