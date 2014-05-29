package XAS::Lib::Modules::Log::Logstash;

our $VERSION = '0.01';

use XAS::Factory;
use Params::Validate 'HASHREF';

use XAS::Class
  base       => 'XAS::Hub',
  version    => $VERSION,
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
        message      => $args->{message},
        hostname     => $args->{hostname},
        priority     => $args->{priority},
        facility     => $args->{facility},
        process      => $args->{process},
        pid          => $args->{pid}
        tid          => '0'
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

XAS::xxx - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::XXX;

=head1 DESCRIPTION

=head1 METHODS

=head2 method1

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
