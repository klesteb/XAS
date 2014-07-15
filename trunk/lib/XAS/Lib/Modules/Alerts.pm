package XAS::Lib::Modules::Alerts;

our $VERSION = '0.04';

use DateTime;
use Try::Tiny;
use XAS::Factory;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Singleton',
  constants  => ':alerts',
  accessors  => 'spooler',
  codec      => 'JSON',
  utils      => 'dt2db',
  filesystem => 'Dir'
;

# ------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------

sub send {
    my $self = shift;

    my $p = $self->validate_params(\@_, { 
        -message  => 1,
        -process  => 1,
        -facility => { optional => 1, default => 'systems', regex => ALERT_FACILITY },
        -priority => { optional => 1, default => 'low', regex => ALERT_PRIORITY }, 
    });

    my $dt = DateTime->now(time_zone => 'local');

    my $data = {
        hostname => $self->env->host,
        datetime => dt2db($dt),
        process  => $p->{'process'},
        pid      => $$,
        msgid    => 0,
        priority => $p->{'priority'},
        facility => $p->{'facility'},
        message  => $p->{'message'},
    };

    my $json = encode($data);

    $self->spooler->write($json);

}

# ------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{spooler} = XAS::Factory->module('spooler', {
        -directory => Dir($self->env->spool, 'alerts'),
        -mask      => 0777
    });

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Modules::Alerts - The alert module for the XAS environment

=head1 SYNOPSIS

Your program can use this module in the following fashion:

 use XAS::Lib::Modules::Alerts;

 my $alert = XAS::Lib::Modules::Alerts->new();

 $alert->send(
     -priority => 'high',
     -facility => 'huston',
     -message  => 'There is a problem'
 );

=head1 DESCRIPTION

This is the module for sending alerts within the XAS environment. It will write
an "alert" to the alerts spool directory. It is implemented as a singleton 
and will auto-load when invoked.

=head1 METHODS

=head2 new

This method initializes the module.

=head2 send

This method will send an alert. It takes the following named parameters:

=over 4

=item B<-priority>

The notification level, 'high','medium','low'. Default 'low'.

=item B<-facility>

The notification facility, 'systems', 'dba', etc.  Default 'systems'.

=item B<-message>

The message text for the message

=back

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
