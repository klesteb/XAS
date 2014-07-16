package XAS::Lib::Stomp::POE::Filter;

our $VERSION = '0.01';

use XAS::Lib::Stomp::Parser;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  accessors => 'filter',
  vars => {
    PARAMS => {
      -target  => { optional => 1, default => '1.0', regex => qr/(1\.0|1\.1|1\.2)/ },
    }
  }
;

# ---------------------------------------------------------------------
# Public methods
# ---------------------------------------------------------------------

sub get_one_start {
    my ($self, $buffers) = @_;

    foreach my $buffer (@$buffers) {

        if (my $frame = $self->filter->parse($buffer)) {

            push(@{$self->{frames}}, $frame);

        }

    }

}

sub get_one {
    my ($self) = shift;

    my @ret;

    if (my $frame = shift(@{$self->{frames}})) {

        push(@ret, $frame);

    }

    return \@ret;

}

sub get_pending {
    my ($self) = shift;

    return $self->filter->get_pending;

}

sub put {
    my ($self, $frames) = @_;

    my @ret;

    foreach my $frame (@$frames) {

        my $buffer = $frame->as_string;

        push(@ret, $buffer);

    }

    return \@ret;

}

# ---------------------------------------------------------------------
# Private methods
# ---------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{filter} = XAS::Lib::Stomp::Parser->new(
        -target => $self->target,
        -xdebug => $self->xdebug,
    );

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Stomp::POE::Filter - An I/O filter for the POE Environment

=head1 SYNOPSIS

  use XAS::Lib::Stomp::POE::Filter;

  For a server

  POE::Component::Server::TCP->new(
      ...
      Filter => XAS::Lib::Stomp::POE::Filter->new(-target => '1.0'),
      ...
  );

  For a client

  POE::Component::Client::TCP->new(
      ...
      Filter => XAS::Lib::Stomp::POE::Filter->new(-target => '1.0'),
      ...
  );

=head1 DESCRIPTION

This module is a filter for the POE environment. It will translate the input
buffer into XAS::Lib::Stomp::Frame objects and serialize the output buffer 
from said object. 

=head1 METHODS

=head2 new

This method initializes the module. It takes these parameters:

=over 4

=item B<-target>

Specify a STOMP protocol version number. It currently supports 1.0,
1.1 and 1.2, defaulting to 1.0.

=back

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

See the documentation for POE::Filter for usage.

For more information on the STOMP protocol, please refer to: L<http://stomp.github.io/> .

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See L<http://dev.perl.org/licenses/> for more information.

=cut
