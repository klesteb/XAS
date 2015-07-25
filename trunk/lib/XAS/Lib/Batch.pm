package XAS::Lib::Batch;

our $VERSION = '0.01';

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  utils   => 'trim',
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

sub _parse_ouput {
    my $self = shift;
    my $output = shift;

    my $stat;

    foreach my $line (@$output) {

        next if ($line eq '');
        next if ($line =~ /variable_list/i);
        next if (index($line, '=') < 0);

        $line = trim($line);

        my ($key, $value) = split('=', $line);

        $key = trim(lc($key));
        $key =~ s/\./_/;

        $stat->{$key} = trim($value);

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
