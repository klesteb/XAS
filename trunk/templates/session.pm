package XAS::;

our $VERSION = '0.01';

use POE;
use Try::Tiny;
use POE::Component::Cron;
use XAS::Lib::POE::PubSub;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Lib::POE::Service',
  mixin      => 'XAS::Lib::Mixins::Handlers',
  vars => {
    PARAMS => {
    }
  }
;

# ---------------------------------------------------------------------
# Public Events
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------

sub session_initialize {
    my $self = shift;

    my $dir;
    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_initialize()");

    $poe_kernel->state('', $self);

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leaving session_initialize()");

}

sub session_startup {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_startup()");

    # walk the chain

    $self->SUPER::session_startup();

    $self->log->debug("$alias: leaving session_startup()");

}

sub session_idle {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_idle()");

    # walk the chain

    $self->SUPER::session_idle();

    $self->log->debug("$alias: leaving session_idle()");

}

sub session_pause {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_pause()");

    # walk the chain

    $self->SUPER::session_pause();

    $self->log->debug("$alias: entering session_pause()");

}

sub session_resume {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_resume()");

    # walk the chain

    $self->SUPER::session_resume();

    $self->log->debug("$alias: entering session_resume()");

}

sub session_shutdown {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_cleanup()");

    # walk the chain

    $self->SUPER::session_shutdown();

    $self->log->debug("$alias: leaving session_cleanup()");

}

# ---------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{'events'} = XAS::Lib::POE::PubSub->new();

    return $self;

}

1;

__END__

=head1 NAME

XAS:: - Perl extension for the XAS environment

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new

This module inherits from L<XAS::Lib::POE::Service|XAS::Lib::POE::Service> and 
takes these additional parameters:

=over 4

=back

=head1 PUBLIC EVENTS

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
