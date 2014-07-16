package XAS::Lib::Modules::Log::Syslog;

our $VERSION = '0.01';

use Params::Validate 'HASHREF';
use Sys::Syslog qw(:standard :extended);

use XAS::Class
  version    => $VERSION,
  base       => 'XAS::Base',
  mixins     => 'init_log output destroy',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub output {
    my $self  = shift;

    $self = $self->prototype() unless ref $self;

    my ($args) = $self->validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $priority = _translate($args->{priority});
    my $message = sprintf('%s', $args->{message});

    syslog($priority, $message);

}

sub destroy {
    my $self = shift;

    closelog();

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _translate {
    my $value = shift;

    my $translate = {
        info  => 'info',
        error => 'err',
        warn  => 'warning',
        fatal => 'alert',
        trace => 'notice',
        debug => 'debug'
    };

    return $translate->{lc($value)};

}

sub init_log {
    my $self = shift;

    setlogsock('unix');
    openlog($self->process, 'pid', $self->facility);

}

1;

__END__

=head1 NAME

XAS::Lib::Modules::Log::Syslog - A mixin class for logging

=head1 DESCRIPTION

This module is a mixin for logging. This logs to syslog.

=head1 METHODS

=head2 init_log

This method initializes syslog. Sets the process, facility and requests that
the pid be included.

=head2 output($hashref)

This method translate the log level to an appropriate syslog priority and
writes out the log line. The translation is a follows:

    info  => 'info',
    error => 'err',
    warn  => 'warning',
    fatal => 'alert',
    trace => 'notice',
    debug => 'debug'

=head2 destroy

Closes the connection to syslog.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See L<http://dev.perl.org/licenses/> for more information.

=cut
