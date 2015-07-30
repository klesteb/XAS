package XAS::Lib::Batch;

our $VERSION = '0.01';

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  utils   => 'dotid run_cmd trim',
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
    TYPES  => qr/user|other|system|,|\s/,
  },
  export => {
    any => 'QSUB QSTAT QDEL QSIG QHOLD QRLS QMSG QMOVE QRERUN QALTER TYPES',
    pbs => 'QSUB QSTAT QDEL QSIG QHOLD QRLS QMSG QMOVE QRERUN QALTER TYPES',
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

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

sub _do_cmd {
    my $self = shift;
    my ($cmd, $sub) $self->params_validate(\@_, [1,1]);

    $self->log->debug("command = $cmd");

    my ($output, $rc, $sig) = run_cmd($cmd);

    if ($rc != 0) {

        my $msg = $output->[0] || '';

        $self->throw_msg(
            dotid($self->class) . ".$sub",
            'pbserr',
            $rc, trim($msg)
        );

    }

    return $output;

}

sub _parse_output {
    my $self = shift;
    my $output = shift;

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
