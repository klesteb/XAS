package XAS::Lib::SSH::Exec;

our $VERSION = '0.01';

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Lib::SSH::Client',
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub setup {
    my $self = shift;

    my $output;

    # Merge stderr and stdout.

    $self->chan->ext_data('merge');

}

sub call {
    my $self = shift;
    my ($command, $parser) = $self->validate_params(\@_,
       { type => SCALAR },
       { type => CODEREF },
    );

    my $output;

    # execute a command, retrieve the output and dispatch to a parser.

    $self->chan->exec($command);
    $output = $self->get();

    return $parser->($output);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::SSH::Exec - A class to execute commands over SSH

=head1 SYNOPSIS

 use XAS::Lib::SSH::Exec;

 my $client = XAS::Lib::SSH::Exec->new(
    -server   => 'test-xen-01',
    -username => 'root',
    -password => 'secret',
 );

 $client->connect();

 my @vms = $client->call('xe vm-list params', sub {
     my $output = shift;
     ...
 });

 $client->disconnect();

=head1 DESCRIPTION

The module uses the SSH Exec subsystem to execute commands. Which means it 
executes a procedure on a remote host and parses the resulting output. This 
module inherits from XAS::Lib::SSH::Client.

=head1 METHODS

=head2 setup

This method will set up the environment to execute commands using the exec
subsystem on a remote system.

=head2 call($command, $parser)

This method execute the command on the remote host and parses the output.

=over 4

=item B<$command>

The command string to be executed.

=item B<$parser>

A coderef to the parser that will parse the returned data. The parser
will accept one parameter which is a reference to that data.

=back

The assumption with this method is that the remote command will return some
sort of parsable data stream. After the data has been parsed the results is
returned to the caller.

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