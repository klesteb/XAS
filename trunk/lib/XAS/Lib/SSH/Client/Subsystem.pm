package XAS::Lib::SSH::Client::Subsystem;

our $VERSION = '0.01';

use Params::Validate qw(CODEREF SCALAR);;
use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Lib::SSH::Client',
  utils   => 'trim',
;

#use Data::Hexdumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub setup {
    my $self = shift;

    my $output;

    # Merge stderr and stdout.

    $self->chan->ext_data('merge');

}

sub run {
    my $self = shift;
    my ($subsystem) = $self->validate_params(\@_, [1] );

    # Invoke the subsystem.

    $self->chan->pty('vt100');   # set up a default pty
    $self->chan->subsystem($subsystem);

    $self->put($self->eol);
    $self->get();

}

sub call {
    my $self = shift;
    my ($command, $parser) = $self->validate_params(\@_, [
       { type => SCALAR },
       { type => CODEREF },
    ]);

    my $output;

    # execute a command, retrieve the output and dispatch to a parser.

    $self->puts($command);
    $output = $self->get();

    return $parser->(trim($output));

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::SSH::Client::Subsystem - A class to interact with the SSH Subsystem facility

=head1 SYNOPSIS

 use XAS::Lib::SSH::Client::Subsystem;

 my $client = XAS::Lib::SSH::Client::Subsystem->new(
    -server    => 'auburn-xen-01',
    -username  => 'root',
    -password  => 'secret',
 );

 $client->connect();
 $client->run('echo');

 my $output = $client->call('this is a test', sub {
     my $output = shift;
     ...
 });

 $client->disconnect();

=head1 DESCRIPTION

The module uses a SSH subsystem to make RPC calls. Which means it 
sends formated packets to the remote host and parses the resulting output. 
This module inherits from L<XAS::Lib::SSH::Client|XAS::Lib::SSH::Client>.

=head1 METHODS

=head2 setup

This method will set up the environment.

=head2 run($subsystem)

This method will invoke a subsystem on the remote host. Wither the remote
host supports subsystems is dependent on the SSH Server that is running.

=over 4

=item B<$subsystem>

The subsystem to invoke.

=back

=head2 call($buffer, $parser)

This method sends a buffer to the remote host and parses the output.

The assumption with this method is that some sort of parsable data stream will
be returned. After the data has been parsed the results are returned to the 
caller.

=over 4

=item B<$buffer>

The buffer to send.

=item B<$parser>

A coderef to the parser that will parse the returned data. The parser
will accept one parameter which is a reference to that data.

=back

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
