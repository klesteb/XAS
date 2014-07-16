package XAS::Lib::Modules::Log::Logstash;

our $VERSION = '0.01';

use XAS::Factory;
use Params::Validate 'HASHREF';

use XAS::Class
  version    => $VERSION,
  base       => 'XAS::Base',
  codecs     => 'JSON',
  accessors  => 'spool',
  filesystem => 'Dir',
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

    my $message = sprintf('[%s] %-5s - %s',
        $args->{datetime}->strftime('%Y-%m-%d %H:%M:%S'),
        uc($args->{priority}), 
        $args->{message}
    );

    # create a logstash "json_event"

    my $data = {
        '@timestamp' => $args->{datetime}->strftime('%Y-%m-%dT%H:%M:%S.%3N%z'),
        '@version'   => '1',
        '@message'   => $message,
        type         => 'xas-log',
        message      => $args->{message},
        hostname     => $args->{hostname},
        priority     => $args->{priority},
        facility     => $args->{facility},
        process      => $args->{process},
        pid          => $args->{pid}
    };

    # write the spool file

    $self->spool->write(encode($data));

}

sub destroy {
    my $self = shift;
    
}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init_log {
    my $self = shift;

    $self->{spool} = XAS::Factory->module('spool', {
        -directory = Dir($self->env->spool, 'logstash')
    });

}

1;

__END__

=head1 NAME

XAS::Lib::Modules::Log::Logstash - A mixin class for logging

=head1 DESCRIPTION

This module is a mixin for logging. It creates a logstash "json_event" which
is then logged to the logstash spool directory.

=head1 METHODS

=head2 init_log

This method initializes the module. It creates a spool object for writing
the "json_event".

=head2 output($hashref)

This method formats the hashref and writes out the results. The JSON data
structure has the following fields:

    @timestamp     - current time in GMT
    @version       - 1
    @message       - the line that would have gone to a log file
    message        - the log line
    hostname       - the hostname
    pid            - the pid of the process
    msgid          - message id
    priority       - the priority from -priority
    facility       - the facility from -facility
    process        - the process  from -process

=head2 destroy

This methods deinitializes the module.

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
