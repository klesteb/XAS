package XAS::Lib::Batch::Interface::Torque;

our $VERSION = '0.01';

use Params::Validate qw/HASHREF ARRAYREF/;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  utils   => 'trim',
  mixins  => 'do_qsub do_qstat do_qdel do_qsig do_qhold do_qrls do_qmove do_qmsg do_qrerun',
  constant => {
    QSUB   => '/usr/bin/qsub',
    QSTAT  => '/usr/bin/qstat',
    QDEL   => '/usr/bin/qdel',
    QSIG   => '/usr/bin/qsig',
    QHOLD  => '/usr/bin/qhold',
    QRLS   => '/usr/bin/qrls',
    QMSG   => '/usr/bin/qmsg',
    QMOVE  => '/usr/bin/qmove',
    QRERUN => '/usr/bin/qrerun',
    QALTER => '/usr/bin/qalter',
  },
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub do_qsub {
    my $self = shift;
    my ($p) = $self->validate_params(\@_, [
        { type => HASHREF }
    ]);
    
    my $queue = _create_queue($self, $p->{'queue'}, $p->{'host'});
    my $cmd = sprintf('%s -q %s %s', QSUB, $queue, $p->{'jobfile'});

    _create_jobfile($self, $p);

    my $output = $self->do_cmd($cmd, 'qsub');

    return trim($output->[0]);

}

sub do_qstat {
    my $self = shift;
    my ($p) = $self->validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $jobid = _create_jobid($self, $p->{'job'}, $p->{'host'});
    my $cmd = sprintf('%s -f1 %s', QSTAT, $jobid);
    my $output = $self->do_cmd($cmd, 'qstat');
    my $stat = _parse_output($self, $output);

    return $stat->{$p->{'job'}};

}

sub do_qdel {
    my $self = shift;
    my ($p) = $self->validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $cmd;
    my $jobid = _create_jobid($self, $p->{'job'}, $p->{'host'});

    $cmd  = sprintf('%s', QDEL);
    $cmd .= sprintf(' -p') if (defined($p->{'force'}));
    $cmd .= sprintf(' -m "%s"', $p->{'message'}) if (defined($p->{'message'}));
    $cmd .= sprintf(' %s', $jobid);

    my $output = $self->do_cmd($cmd, 'qdel');

    return 1;

}

sub do_qsig {
    my $self = shift;
    my ($p) = $self->validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $jobid = _create_jobid($self, $p->{'job'}, $p->{'host'});
    my $cmd  = sprintf('%s -s %s %s', QSIG, $p->{'signal'}, $jobid);
    my $output = $self->do_cmd($cmd, 'qsig');

    return 1;

}

sub do_qhold {
    my $self = shift;
    my ($p) = $self->validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $cmd;
    my $hold;
    my $jobid = _create_jobid($self, $p->{'job'}, $p->{'host'});

    foreach my $x (split(DELIMITER, $p->{'type'})) {

        $hold .= 'u' if ($x eq 'user');
        $hold .= 'o' if ($x eq 'other');
        $hold .= 's' if ($x eq 'system');

    }

    $cmd  = sprintf('%s -h %s %s', QHOLD, $hold, $jobid);

    my $output = $self->do_cmd($cmd, 'qhold');

    return 1;

}

sub do_qrls {
    my $self = shift;
    my ($p) = $self->validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $cmd;
    my $hold;
    my $jobid = _create_jobid($self, $p->{'job'}, $p->{'host'});

    foreach my $x (split(DELIMITER, $p->{'type'})) {

        $hold .= 'u' if ($x eq 'user');
        $hold .= 'o' if ($x eq 'other');
        $hold .= 's' if ($x eq 'system');

    }

    $cmd  = sprintf('%s -h %s %s', QRLS, $hold, $jobid);

    my $output = $self->do_cmd($cmd, 'qrls');

    return 1;

}

sub do_qmove {
    my $self = shift;
    my ($p) = $self->validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $jobid = _create_jobid($self, $p->{'job'}, $p->{'host'});
    my $queue = _create_queue($self, $p->{'queue'}, $p->{'dhost'});
    my $cmd = sprintf('%s %s %s', QMOVE, $queue, $jobid);
    my $output = $self->do_cmd($cmd, 'qmove');

    return 1;

}

sub do_qmsg {
    my $self = shift;
    my ($p) = $self->validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $jobid = _create_jobid($self, $p->{'job'}, $p->{'host'});
    my $cmd  = sprintf('%s -%s "%s" %s', QMSG, $p->{'output'}, $p->{'message'}, $jobid);
    my $output = $self->do_cmd($cmd, 'qmsg');

    return 1;

}

sub do_qrerun {
    my $self = shift;
    my ($p) = $self->validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $jobid = _create_jobid($self, $p->{'job'}, $p->{'host'});
    my $cmd  = sprintf('%s %s', QRERUN, $jobid);
    my $output = $self->do_cmd($cmd, 'qrerun');

    return 1;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _create_jobid {
    my $self = shift;
    my ($id, $host) = $self->validate_params(\@_, [
        1,
        { optional => 1, default => undef }
    ]);

    my $jobid;

    if (defined($host)) {

        $jobid = sprintf("%s\@%s", $id, $host);

    } else {

        $jobid = $id;

    }

    return $jobid;

}

sub _create_queue {
    my $self = shift;
    my ($queue, $host) = $self->validate_params(\@_, [
        1,
        { optional => 1, default => undef }
    ]);

    my $que;

    if (defined($host)) {

        $que = sprintf("%s\@%s", $queue, $host);

    } else {

        $que = $queue;

    }

    return $que;

}

sub _parse_output {
    my $self = shift;
    my ($output) = $self->validate_params(\@_, [
        { type => ARRAYREF }
    ]);

    my $id;
    my $stat;

    foreach my $line (@$output) {

        next if ($line eq '');

        $line = trim($line);

        if ($line =~ /^Job Id/) {

            ($id) = ($line =~ m/^Job Id\:\s(.*)/);
            $id = trim($id);
            next;

        }

        if ($line =~ /^Queue/) {

            ($id) = ($line =~ m/^Queue\:\s(.*)/);
            $id = trim($id);
            next;

        }

        if ($line =~ /^Server/) {

            ($id) = ($line =~ m/^Server\:\s(.*)/);
            $id = trim($id);
            next;

        }

        next if (index($line, '=') < 0);

        my ($key, $value) = split('=', $line, 2);

        $key = trim(lc($key));
        $key =~ s/\./_/;

        $stat->{$id}->{$key} = trim($value);

    }

    return $stat;

}

sub _create_jobfile {
    my $self = shift;
    my ($p) = $self->validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $after;
    my $logfile;
    my $job = $p->{'jobfile'};
    my $fh  = $job->open('w');

    if (defined($p->{'host'})) {

        $logfile = sprintf("%s:%s", $p->{'host'}, $p->{'logfile'});

    } else {

        $logfile = $p->{'logfile'};

    }

    if (defined($p->{'after'})) {

        $after = $p->{'after'}->strftime('%Y%m%d%H%M');

    }

    $fh->printf("#!/bin/sh\n");
    $fh->printf("#\n");
    $fh->printf("#PBS -N \"%s\"\n", $p->{'jobname'});
    $fh->printf("#PBS -j \"%s\"\n", $p->{'join_path'});
    $fh->printf("#PBS -e %s\n", $logfile);
    $fh->printf("#PBS -o %s\n", $logfile);
    $fh->printf("#PBS -m \"%s\"\n", $p->{'mail_points'});
    $fh->printf("#PBS -M \"%s\"\n", $p->{'email'});
    $fh->printf("#PBS -S %s\n", $p->{'shell_path'});
    $fh->printf("#PBS -w %s\n", $p->{'work_path'});
    $fh->printf("#PBS -d %s\n", $p->{'work_path'});
    $fh->printf("#PBS -p %s\n", $p->{'priority'});
    $fh->printf("#PBS -r %s\n", $p->{'rerunable'});
    $fh->printf("#PBS -u %s\n", $p->{'user'}) if (defined($p->{'user'}));
    $fh->printf("#PBS -A %s\n", $p->{'account'}) if (defined($p->{'account'}));
    $fh->printf("#PBS -a %s\n", $after) if (defined($p->{'after'}));
    $fh->printf("#PBS -l \"%s\"\n", $p->{'resources'}) if (defined($p->{'resources'}));
    $fh->printf("#PBS -W \"%s\"\n", $p->{'attributes'}) if (defined($p->{'attributes'}));
    $fh->printf("#PBS -v \"%s\"\n", $p->{'environment'}) if (defined($p->{'environment'}));
    $fh->printf("#PBS -n \n") if (defined($p->{'exclusive'}));
    $fh->printf("#PBS -h \n") if (defined($p->{'hold'}));
    $fh->printf("#PBS -V \n") if (defined($p->{'env_export'}));
    $fh->printf("#\n");
    $fh->printf("%s\n", $p->{'command'});
    $fh->printf("#\n");
    $fh->printf("exit \$?\n");

    $fh->close;

}

1;

__END__

=head1 NAME

XAS::Lib::Mixins::xxxx - A mixin for the XAS environment

=head1 SYNOPSIS

 use XAS::Class
   debug   => 0,
   version => '0.01',
   base    => 'XAS::Base',
   mixin   => 'XAS::Lib::Mixins::xxxx'
;

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
