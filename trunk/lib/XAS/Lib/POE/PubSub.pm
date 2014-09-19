package XAS::Lib::POE::PubSub;

our $VERSION = '0.01';

use POE;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Singleton',
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub subscribe {
    my $self = shift;
    my ($session, $channel) = $self->validate_params(\@_, [
        1,
        { optional => 1, default => 'default' }
    ]);

    $self->{registry}->{$channel}->{$session} = $session;

}

sub unsubscribe {
    my $self = shift;
    my ($session, $channel) = $self->validate_params(\@_, [
        1,
        { optional => 1, default => 'default' }
    ]);

    delete $self->{registry}->{$channel}->{$session};

}

sub publish {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
       -event   => 1,
       -args    => { optional => 1, default => undef },
       -channel => { optional => 1, default => 'default' },
    });

    my $event   = $p->{event};
    my $channel = $p->{channel};
    my $args    = $p->{args};

    foreach my $session (keys %{$self->{registry}->{$channel}}) {

        $poe_kernel->post($session, $event, $args);

    }

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{registry} = {};

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::POE::PubSub - A class for the XAS environment

=head1 SYNOPSIS

 use POE;
 use XAS::Lib::POE::PubSub;

 my $pubsub = XAS::Lib::POE::PubSub->new();

 $pubsub->subscribe('session', 'channel');
 $pubusb->publish(
    -event   => 'event',
    -channel => 'channel', 
 );

=head1 DESCRIPTION

This is a very simple channel based publish/subscribe framework for POE. It 
is implemented as a singleton. It allows you to publish events to all 
interested sessions.

=head1 METHODS

=head2 subscribe($session, $channel);

This method allows you to subscribe to the specified channel. 

=over 4

=item B<$session>

The session name.

=item B<$channel>

The optional channel to subscribe too. Defaults to 'default'.

=back

=head2 unsubscribe($session, $channel);

This method allows you to unsubscribe from the specified channel. 

=over 4

=item B<$session>

The session name.

=item B<$channel>

The optional channel to unsubscribe from. Defaults to 'default'.

=back

=head2 publish

This method allows you to publish an event to a specified channel. Additional
aruguments can be supplied. It takes the following parameters:

=over 4

=item B<-event>

The event to send.

=item B<-channel>

Optional channel. Defaults to 'default'.

=item B<-args>

Optional additional arugments to send with the event. The context of the 
arguments is determined by the method that is handling the event. For example:

 -args => ['this', 'is', 'neat']
 -args => { this => 'is neat' }
 -args => 'this is neat'

Are all valid arguments. 

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
