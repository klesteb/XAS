package XAS::Lib::Modules::PidFile::Unix;

our $VERSION = '0.01';

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  mixins  => 'is_running scan_name',
  utils   => 'run_cmd trim compress',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub scan_name {
    my $self = shift;

    # just return the name of the script

    return $self->class->any_var('SCRIPT');

}

sub is_running {
    my $self = shift;

    my $pid = $self->_get_pid();
    my $commandline = $self->scan_name();

    if (defined($pid)) {

        # use ps to scan for an existing process with this pid

        my $command = "ps -p $pid -o comm=";
        my ($output, $rc) = run_cmd($command);

        if ($rc == 0) {

            foreach my $line (@$output) {

                $line = compress(trim($line));
                $self->log->debug(sprintf("\"%s\" = \"%s\"", $commandline, $line));

                return $pid if ($commandline =~ /$line/);

            }

        }

    }

    return undef;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Modules::PidFile::Unix - A mixin class to scan for processes on Unix

=head1 DESCRIPTION

This is a mixin class to provide process scanning on a Unix platform. It
ps to do the process scan.

=head1 METHODS

=head2 is_running

Please see L<XAS::Lib::Modules::PidFile|XAS::Lib::Modules::PidFile> for usage.

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
