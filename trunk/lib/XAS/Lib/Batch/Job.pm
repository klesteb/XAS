package XAS::Lib::Batch::Job;

our $VERSION = '0.01';

use XAS::Class
  debug    => 0,
  version  => $VERSION,
  base     => 'XAS::Lib::Batch',
  constant => ':pbs DELIMITER',
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
        -cmd     => 1,
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

    my $queue = $self->_create_queue($p->{'-queue'}, $p->{'-host'});
    my $cmd = sprintf('%s -q %s %s', QSUB, $queue, $p->{'-jobfile'});

    $self->_create_jobfile($p);

    my $output = $self->_do_cmd($cmd, 'qsub');

    return trim($output->[0]);

}

sub qstat {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -job  => 1,
        -host => { optional => 1, default => undef },
    });

    my $jobid = $self->_create_jobid($p->{'-job'}, $p->{'-host'});
    my $cmd = sprintf('%s -f1 %s', QSTAT, $jobid);
    my $output = $self->_do_cmd($cmd, 'qstat');

    $stat = $self->_parse_output($output);

    return $stat;

}

sub qdel {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -job     => 1,
        -host    => { optional => 1, default => undef },
        -force   => { optional => 1, default => undef },
        -message => { optional => 1, default => undef },
    });

    my $cmd;
    my $jobid = $self->_create_jobid($p->{'-job'}, $p->{'-host'});

    $cmd  = sprintf('%s', QDEL);
    $cmd .= sprintf(' -p') if (defined($p->{'-force'}));
    $cmd .= sprintf(' -m "%s"', $p->{'-message'}) if (defined($p->{'-message'}));
    $cmd .= sprintf(' %s', $jobid);

    my $output = $self->_do_cmd($cmd, 'qdel');

    return 1;

}

sub qsig {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -job    => 1,
        -signal => 1,
        -host   => { optional => 1, default => undef },
    });

    my $jobid = $self->_create_jobid($p->{'-job'}, $p->{'-host'});
    my $cmd  = sprintf('%s -s %s %s', QSIG, $p->{'-signal'}, $jobid);
    my $output = $self->_do_cmd($cmd, 'qsig');

    return 1;

}

sub qhold {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -job  => 1,
        -type => { regex => TYPES }, 
        -host => { optional => 1, default => undef },
    });

    my $cmd;
    my $hold;
    my $jobid = $self->_create_jobid($p->{'-job'}, $p->{'-host'});

    foreach my $x (split(DELIMITER, $p->{'-type'})) {

        $hold .= 'u' if ($x eq 'user');
        $hold .= 'o' if ($x eq 'other');
        $hold .= 's' if ($x eq 'system');

    }

    $cmd  = sprintf('%s -h %s %s', QHOLD, $hold, $jobid);

    my $output = $self->_do_cmd($cmd, 'qhold');

    return 1;

}

sub qrls {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -job  => 1,
        -type => { regex => TYPES }, 
        -host => { optional => 1, default => undef },
    });

    my $cmd;
    my $hold;
    my $jobid = $self->_create_jobid($p->{'-job'}, $p->{'-host'});

    foreach my $x (split(DELIMITER, $p->{'-type'})) {

        $hold .= 'u' if ($x eq 'user');
        $hold .= 'o' if ($x eq 'other');
        $hold .= 's' if ($x eq 'system');

    }

    $cmd  = sprintf('%s -h %s %s', QRLS, $hold, $jobid);

    my $output = $self->_do_cmd($cmd, 'qrls');

    return 1;

}

sub qmove {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -job   => 1,
        -queue => 1,
        -host  => { optional => 1, default => undef },
        -dhost => { optional => 1, default => undef },
    });

    my $jobid = $self->_create_jobid($p->{'-job'}, $p->{'-host'});
    my $queue = $self->_create_queue($p->{'-queue'}, $p->{'-dhost'});
    my $cmd = sprintf('%s %s %s', QMOVE, $queue, $jobid);
    my $output = $self->_do_cmd($cmd, 'qmove');

    return 1;

}

sub qmsg {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -job     => 1,
        -message => 1,
        -output  => { regex => /E|O/ },
        -host    => { optional => 1, default => undef },
    });

    my $jobid = $self->_create_jobid($p->{'-job'}, $p->{'-host'});
    my $cmd  = sprintf('%s -%s "%s" %s', QMSG, $p->{'-output'}, $p->{'-message'}, $jobid);
    my $output = $self->_do_cmd($cmd, 'qmsg');

    return 1;

}

sub qrerun {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -job  => 1,
        -host => { optional => 1, default => undef },
    });

    my $jobid = $self->_create_jobid($p->{'-job'}, $p->{'-host'});
    my $cmd  = sprintf('%s %s', QRERUN, $jobid);
    my $output = $self->_do_cmd($cmd, 'qrerun');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _create_jobfile {
    my $self = shift;
    my $p    = shift;

    my $after;
    my $logfile;
    my $job = $p->{'-jobfile'};
    my $fh  = $job->open('w');

    if (defined($p->{'-host'})) {

        $logfile = sprintf("%s:%s", $p->{'-host'}, $p->{'-logfile'});

    } else {

        $logfile = $p->{'-logfile'};

    }

    if (defined($p->{'-after'})) {

        $after = $p->{'-after'}->strftime('%Y%m%d%H%M');

    }

    $fh->printf("#!/bin/sh\n");
    $fh->printf("#\n");
    $fh->printf("#PBS -N \"%s\"\n", $p->{'-jobname'});
    $fh->printf("#PBS -j \"%s\"\n", $p->{'-join_path'});
    $fh->printf("#PBS -e %s\n", $logfile);
    $fh->printf("#PBS -o %s\n", $logfile);
    $fh->printf("#PBS -m \"%s\"\n", $p->{'-mail_points'});
    $fh->printf("#PBS -M \"%s\"\n", $p->{'-email'});
    $fh->printf("#PBS -S %s\n", $p->{'-shell_path'});
    $fh->printf("#PBS -w %s\n", $p->{'-work_path'});
    $fh->printf("#PBS -d %s\n", $p->{'-work_path'});
    $fh->printf("#PBS -p %s\n", $p->{'-priority'});
    $fh->printf("#PBS -r %s\n", $p->{'-rerunable'});
    $fh->printf("#PBS -u %s\n", $p->{'-user'}) if (defined($p->{'-user'}));
    $fh->printf("#PBS -A %s\n", $p->{'-account'}) if (defined($p->{'-account'}));
    $fh->printf("#PBS -a %s\n", $after) if (defined($p->{'-after'}));
    $fh->printf("#PBS -l \"%s\"\n", $p->{'-resources'}) if (defined($p->{'-resources'}));
    $fh->printf("#PBS -W \"%s\"\n", $p->{'-attributes'}) if (defined($p->{'-attributes'}));
    $fh->printf("#PBS -v \"%s\"\n", $p->{'-environment'}) if (defined($p->{'-environment'}));
    $fh->printf("#PBS -n \n") if (defined($p->{'-exclusive'}));
    $fh->printf("#PBS -h \n") if (defined($p->{'-hold'}));
    $fh->printf("#PBS -V \n") if (defined($p->{'-env_export'}));
    $fh->printf("#\n");
    $fh->printf("%s\n", $p->{'-cmd'});
    $fh->printf("#\n");
    $fh->printf("exit \$?\n");

    $fh->close;

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    return $self;

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

Copyright (c) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
