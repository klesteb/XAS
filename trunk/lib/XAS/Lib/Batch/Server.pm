package XAS::Lib::Batch::Server;

our $VERSION = '0.01';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::Batch',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub qstat {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -queue => { optional => 1, default => undef },
        -host  => { optional => 1, default => undef },
    });

    return $self->do_server_stat($p);

}

sub qenable {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -queue => { optional => 1, default => undef },
        -host  => { optional => 1, default => undef },
    });

    return $self->do_server_enable($p);

}

sub qdisable {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -queue => { optional => 1, default => undef },
        -host  => { optional => 1, default => undef },
    });

    return $self->do_server_disable($p);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

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

Copyright (c) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
