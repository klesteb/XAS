package XAS::Lib::Batch::Job;

our $VERSION = '0.01';

use XAS::Class
  debug    => 0,
  version  => $VERSION,
  base     => 'XAS::Lib::Batch',
  utils    => 'dotid trim run_cmd',
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
        -work_path   => { optional => 1, default => '/wise/logs' },
        -priority    => { optional => 1, default => 0, callbacks => {
            'out of priority range' =>
            sub { $_[0] > -1024 && $_[0] < 1024; },
        }}
    });

    my $queue = $p->{'-queue'};
    $queue .= "\@" . $p->{'-host'} if (defined($p->{'-host'}));

    $self->_create_jobfile($p);

    my $cmd = sprintf('%s -q %s %s', QSUB, $queue, $p->{'-jobfile'});

    $self->log->debug("command = $cmd");

    my ($output, $rc, $sig) = run_cmd($cmd);

    if ($rc != 0) {

        my $msg = $output->[0] || '';

        $self->throw_msg(
            dotid($self->class) . '.qsub',
            'pbserr',
            $rc, trim($msg)
        );

    }

    return trim($output->[0]);

}

sub qstat {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -job  => 1,
        -host => { optional => 1, default => undef },
    });

    my $cmd;
    my $stat;
    my $jobid;

    if (defined($p->{'-host'})) {

        $jobid = sprintf("%s\@%s", $p->{'-job'}, $p->{'-host'});

    } else {

        $jobid = $p->{'-job'};

    }

    $cmd = sprintf('%s -f1 %s', QSTAT, $jobid);

    $self->log->debug("command = $cmd");

    my ($output, $rc, $sig) = run_cmd($cmd);

    if ($rc != 0) {

        my $msg = $output->[0] || '';

        $self->throw_msg(
            dotid($self->class) . '.qstat',
            'pbserr',
            $rc, trim($msg)
        );

    }

    shift @$output; # strip the job id line

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
    my $stat;
    my $jobid;

    if (defined($p->{'-host'})) {

        $jobid = sprintf("%s\@%s", $p->{'-job'}, $p->{'-host'});

    } else {

        $jobid = $p->{'-job'};

    }

    $cmd  = sprintf('%s', QDEL);
    $cmd .= sprintf(' -p') if (defined($p->{'-force'}));
    $cmd .= sprintf(' -m "%s"', $p->{'-message'}) if (defined($p->{'-message'}));
    $cmd .= sprintf(' %s', $jobid);

    $self->log->debug("command = $cmd");

    my ($output, $rc, $sig) = run_cmd($cmd);

    if ($rc != 0) {

        my $msg = $output->[0] || '';

        $self->throw_msg(
            dotid($self->class) . '.qdel',
            'pbserr',
            $rc, trim($msg)
        );

    }

}

sub qsig {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -job    => 1,
        -signal => 1,
        -host   => { optional => 1, default => undef },
    });

    my $cmd;
    my $stat;
    my $jobid;

    if (defined($p->{'-host'})) {

        $jobid = sprintf("%s\@%s", $p->{'-job'}, $p->{'-host'});

    } else {

        $jobid = $p->{'-job'};

    }

    $cmd  = sprintf('%s -s %s %s', QSIG, $p->{'-signal'}, $jobid);

    $self->log->debug("command = $cmd");

    my ($output, $rc, $sig) = run_cmd($cmd);

    if ($rc != 0) {

        my $msg = $output->[0] || '';

        $self->throw_msg(
            dotid($self->class) . '.qsig',
            'pbserr',
            $rc, trim($msg)
        );

    }

}

sub qhold {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -job  => 1,
        -type => { regex => TYPES }, 
        -host => { optional => 1, default => undef },
    });

    my $cmd;
    my $stat;
    my $hold;
    my $jobid;

    if (defined($p->{'-host'})) {

        $jobid = sprintf("%s\@%s", $p->{'-job'}, $p->{'-host'});

    } else {

        $jobid = $p->{'-job'};

    }

    foreach my $x (split(DELIMITER, $p->{'-type'})) {
        
        $hold .= 'u' if ($x eq 'user');
        $hold .= 'o' if ($x eq 'other');
        $hold .= 's' if ($x eq 'system');
        
    }
    
    $cmd  = sprintf('%s -h %s %s', QHOLD, $hold, $jobid);

    $self->log->debug("command = $cmd");

    my ($output, $rc, $sig) = run_cmd($cmd);

    if ($rc != 0) {

        my $msg = $output->[0] || '';

        $self->throw_msg(
            dotid($self->class) . '.qhold',
            'pbserr',
            $rc, trim($msg)
        );

    }

}

sub qrls {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -job  => 1,
        -type => { regex => TYPES }, 
        -host => { optional => 1, default => undef },
    });

    my $cmd;
    my $stat;
    my $hold;
    my $jobid;

    if (defined($p->{'-host'})) {

        $jobid = sprintf("%s\@%s", $p->{'-job'}, $p->{'-host'});

    } else {

        $jobid = $p->{'-job'};

    }

    foreach my $x (split(DELIMITER, $p->{'-type'})) {

        $hold .= 'u' if ($x eq 'user');
        $hold .= 'o' if ($x eq 'other');
        $hold .= 's' if ($x eq 'system');

    }

    $cmd  = sprintf('%s -h %s %s', QRLS, $hold, $jobid);

    $self->log->debug("command = $cmd");

    my ($output, $rc, $sig) = run_cmd($cmd);

    if ($rc != 0) {

        my $msg = $output->[0] || '';

        $self->throw_msg(
            dotid($self->class) . '.qrls',
            'pbserr',
            $rc, trim($msg)
        );

    }

}

sub qmove {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -job   => 1,
        -queue => 1,
        -host  => { optional => 1, default => undef },
        -dhost => { optional => 1, default => undef },
    });

    my $cmd;
    my $stat;
    my $hold;
    my $jobid;
    my $queue;

    if (defined($p->{'-host'})) {

        $jobid = sprintf("%s\@%s", $p->{'-job'}, $p->{'-host'});

    } else {

        $jobid = $p->{'-job'};

    }
    
    if (defined($p->{'-dhost'})) {
        
        $queue = sprintf("%s\@%s", $p->{'-queue'}, $p->{'-dhost'});

    } else {
        
        $queue = $p->{'-queue'};
        
    }

    $cmd  = sprintf('%s %s %s', QMOVE, $queue, $jobid);

    $self->log->debug("command = $cmd");

    my ($output, $rc, $sig) = run_cmd($cmd);

    if ($rc != 0) {

        my $msg = $output->[0] || '';

        $self->throw_msg(
            dotid($self->class) . '.qmove',
            'pbserr',
            $rc, trim($msg)
        );

    }

}

sub qmsg {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -job     => 1,
        -message => 1,
        -output  => { regex => /E|O/ },
        -host    => { optional => 1, default => undef },
    });

    my $cmd;
    my $stat;
    my $hold;
    my $jobid;

    if (defined($p->{'-host'})) {

        $jobid = sprintf("%s\@%s", $p->{'-job'}, $p->{'-host'});

    } else {

        $jobid = $p->{'-job'};

    }

    $cmd  = sprintf('%s -%s "%s" %s', QMSG, $p->{'-output'}, $p->{'-message'}, $jobid);

    $self->log->debug("command = $cmd");

    my ($output, $rc, $sig) = run_cmd($cmd);

    if ($rc != 0) {

        my $msg = $output->[0] || '';

        $self->throw_msg(
            dotid($self->class) . '.qmsg',
            'pbserr',
            $rc, trim($msg)
        );

    }

}

sub qrerun {
    my $self = shift;
    my $p = $self->validate_params(\@_, {
        -job  => 1,
        -host => { optional => 1, default => undef },
    });

    my $cmd;
    my $stat;
    my $jobid;

    if (defined($p->{'-host'})) {

        $jobid = sprintf("%s\@%s", $p->{'-job'}, $p->{'-host'});

    } else {

        $jobid = $p->{'-job'};

    }

    $cmd  = sprintf('%s %s', QRERUN, $jobid);

    $self->log->debug("command = $cmd");

    my ($output, $rc, $sig) = run_cmd($cmd);

    if ($rc != 0) {

        my $msg = $output->[0] || '';

        $self->throw_msg(
            dotid($self->class) . '.qrerun',
            'pbserr',
            $rc, trim($msg)
        );

    }

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
