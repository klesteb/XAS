package XAS::Lib::Session;

our $VERSION = '0.03';

use POE;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  utils     => 'weaken',
  accessors => 'session',
  vars => {
    PARAMS => {
      -alias  => { optional => 1, default => 'session' },
    }
  }
;

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub session_initialize {
    my $self = shift;

    $poe_kernel->sig(HUP  => 'session_interrupt');
    $poe_kernel->sig(INT  => 'session_interrupt');
    $poe_kernel->sig(TERM => 'session_interrupt');
    $poe_kernel->sig(QUIT => 'session_interrupt');

}

sub session_startup {
    my $self = shift;

}

sub session_shutdown {
    my $self = shift;

}

sub session_reload {
    my $self = shift;

    $poe_kernel->sig_handled();

}

sub session_interrupt {
    my $self   = shift;
    my $signal = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: session_interrupt()");
    $self->log->warn_msg('signaled', $alias, $signal);

    if ($signal eq 'HUP') {

        $self->session_reload();

    } else {

        $self->session_shutdown();

    }

}

sub session_stop {
    my $self = shift;

}

sub run {
    my $self = shift;

    $poe_kernel->run();

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    # initialize POE, this removes an error message if a failure happens later

    $poe_kernel->run();

    # walk the chain

    my $self = $class->SUPER::init(@_);

    # set up the session

    $self->{session} = POE::Session->create(
        object_states => [
            $self => {
                _start            => '_session_start',
                _stop             => '_session_stop',
                session_init      => '_session_init',
                session_reload    => '_session_reload',
                session_startup   => '_session_startup',
                session_shutdown  => '_session_shutdown',
                session_interrupt => '_session_interrupt',
            },
        ]
    );

    weaken($self->{session});

    return $self;

}

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _session_start {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: _session_start()");

    if ((my $rc = $poe_kernel->alias_set($alias)) > 0) {

        $self->throw_msg(
            'xas.session._session_start.noalias',
            'noalias',
            $alias
        );

    }

    $poe_kernel->post($alias, 'session_init');

}

sub _session_init {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: _session_init()");

    $self->session_initialize();

    $poe_kernel->post($alias, 'session_startup');

}

sub _session_startup {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: _session_startup()");

    $self->session_startup();

}

sub _session_shutdown {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: _session_shutdown()");

    $self->session_shutdown();

}

sub _session_reload {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: _session_reload()");

    $self->session_reload();

}

sub _session_stop {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: _session_stop()");

    $self->session_stop();

    $poe_kernel->alias_remove($self->alias);

}

sub _session_interrupt {
    my ($self, $signal) = @_[OBJECT,ARG0];

    my $alias = $self->alias;

    $self->log->debug("$alias: _session_interrupt()");

    $self->session_interrupt($signal);

}

1;

__END__

=head1 NAME

XAS::Lib::Session - The base class for all POE Sessions.

=head1 SYNOPSIS

 my $session = XAS::Lib::Session->new(
     -alias => 'name',
 );

=head1 DESCRIPTION

This module provides an object based POE session. This object will perform
the necessary actions for the lifetime of the session. This includes handling
signals. The following signals INT, TERM, QUIT will trigger the 'shutdown'
event which invokes the session_cleanup() method. The HUP signal will invoke 
the session_reload() method. This module inherits from XAS::Base.

=head1 METHODS

=head2 session_initialize

This is where the session should do whatever initialization it needs. This
initialization may include defining additional events.

=head2 session_cleanup

This method should perform cleanup actions for the session. This is triggered
by a "shutdown" event.

=head2 session_reload

This method should perform reload actions for the session. By default it
calls $kernel->sig_handled() which terminates further handling of the HUP
signal.

=head2 session_stop

This method should perform stop actions for the session. This is triggered
by a "_stop" event.

=head1 PUBLIC EVENTS

The following public events are defined for the session.

=head2 session_startup

This event should start whatever processing the session will do. It is passed
two parameters:

=head2 session_shutdown

When you send this event to the session, it will invoke the session_cleanup() 
method.

=head1 PRIVATE EVENTS

The following events are used internally:

 session_init
 session_interrupt
 session_reload
 shutdown

They should only be used with caution.

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
