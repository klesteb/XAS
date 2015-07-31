package XAS::Lib::Batch::Job;

our $VERSION = '0.01';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::Batch',
  constants => 'DELIMITER',
  constant => {
    TYPES  => qr/user|other|system|,|\s/,
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub qsub {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -jobname => 1,
        -queue   => 1,
        -email   => 1,
        -command => 1,
        -jobfile => { isa => 'Badger::Filesystem::File' },
        -logfile => { isa => 'Badger::Filesystem::File' },
        -rerunable   => { optional => 1, default => 'y' },
        -join_path   => { optional => 1, default => 'oe' },
        -account     => { optional => 1, default => undef },
        -attributes  => { optional => 1, default => undef },
        -environment => { optional => 1, default => undef },
        -env_export  => { optional => 1, default => undef },
        -exclusive   => { optional => 1, default => undef },
        -hold        => { optional => 1, default => undef },
        -resources   => { optional => 1, default => undef },
        -user        => { optional => 1, default => undef },
        -host        => { optional => 1, default => undef },
        -mail_points => { optional => 1, default => 'bea' },
        -after       => { optional => 1, isa => 'DateTime' },
        -shell_path  => { optional => 1, default => '/bin/sh' },
        -work_path   => { optional => 1, default => '/tmp' },
        -priority    => { optional => 1, default => 0, callbacks => {
            'out of priority range' =>
            sub { $_[0] > -1024 && $_[0] < 1024; },
        }}
    });

    return $self->do_qsub($p);

}

sub qstat {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -job  => 1,
        -host => { optional => 1, default => undef },
    });

    return $self->do_qstat($p);

}

sub qdel {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -job     => 1,
        -host    => { optional => 1, default => undef },
        -force   => { optional => 1, default => undef },
        -message => { optional => 1, default => undef },
    });

    return $self->do_qdel($p);

}

sub qsig {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -job    => 1,
        -signal => 1,
        -host   => { optional => 1, default => undef },
    });

    return $self->do_qsig($p);

}

sub qhold {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -job  => 1,
        -type => { regex => TYPES }, 
        -host => { optional => 1, default => undef },
    });

    return $self->do_qhold($p);

}

sub qrls {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -job  => 1,
        -type => { regex => TYPES }, 
        -host => { optional => 1, default => undef },
    });

    return $self->do_qrls($p);

}

sub qmove {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -job   => 1,
        -queue => 1,
        -host  => { optional => 1, default => undef },
        -dhost => { optional => 1, default => undef },
    });

    return $self->do_qmove($p);

}

sub qmsg {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -job     => 1,
        -message => 1,
        -output  => { regex => /E|O/ },
        -host    => { optional => 1, default => undef },
    });

    return $self->do_qmsg($p);

}

sub qrerun {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -job  => 1,
        -host => { optional => 1, default => undef },
    });

    return $self->do_qrerun($p);

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
