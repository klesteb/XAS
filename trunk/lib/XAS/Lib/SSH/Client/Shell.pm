package XAS::Lib::SSH::Client::Shell;

our $VERSION = '0.01';

use Params::Validate qw(SCALAR CODEREF);
use XAS::Class
  debug    => 0,
  version  => $VERSION,
  base     => 'XAS::Lib::SSH::Client',
  mutators => 'eol',
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

    # The following needs to be done to talk with a
    # KpyM SSH Server, other servers don't seem to care.

    $self->chan->pty('vt100');   # set up a default pty
    $self->chan->shell();        # ask for a shell
    $self->put($self->eol);      # flush output buffer

    # Flush the input buffer. Discards any banners, welcomes,
    # announcements, motds and other assorted stuff.

    while ($output = $self->get()) {

        # Parse the output looking for specific strings. There
        # must be a better way...

        if ($output =~ /\[3;1f$/ ) {

            # Found a KpyM SSH Server, with the naq screen...
            #
            # Also KpyM (cmd.exe??) needs a \r\n eol for command
            # execution. Bitvise dosen't seem to require this.

            $self->eol("\015\012");

            # Need to wait for the "continue" line. Pay the
            # danegield, but don't register the key, or this
            # code will stop working!

            while ($output = $self->get()) {

                if ($output =~ /continue\./) {

                    $self->put($self->eol);

                }

            }

        } elsif ($output =~ /\[c$/) {

            # Found an OpenVMS SSH server. SET TERM/INQUIRE must
            # be set for this code to work. DCL expects a \r\n
            # eol for command execution.

            $self->eol("\015\012");

            # Wait for this line, it indicates that the terminal
            # capabilities negotiation has finished.

            do {

                $output = $self->get();

            } until ($output =~ /\[0c$/);

            $self->put($self->eol);

        }

    }

}

sub run {
    my $self = shift;
    my ($command) = $self->validate_params(\@_, [1] );

    my $buffer = sprintf("%s%s", $command, $self->eol);

    $self->put($buffer);      # send the command
    $self->get();             # remove the echo back

}

sub call {
    my $self = shift;
    my ($command, $parser) = $self->validate_params(\@_, [
       { type => SCALAR },
       { type => CODEREF },
    ]);

    my $output;
    my $buffer = sprintf("%s%s", $command, $self->eol);

    # execute a command, retrieve the output and dispatch to a parser.

    $self->put($buffer);        # this will be echoed back
    $output = $self->get();     # get the output
    $output =~ s/$command//;    # strip the original buffer;

    return $parser->(trim($output));    # remove line endings

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->eol("\012");

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::SSH::Client::Shell - A class to interact with the SSH Shell facility

=head1 SYNOPSIS

 use XAS::Lib::SSH::Client::Shell;

 my $client = XAS::Lib::SSH::Client::Shell->new(
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

This module uses the SSH Shell subsystem to execute commands. Which means it 
executes a procedure on a remote host and parses the resulting output. This 
module inherits from XAS::Lib::SSH::Client.

=head1 METHODS

=head2 setup

This method will set up the environment to execute commands using the shell
subsystem on a remote system.

=head2 run($command)

Run a command. The purpose is to run a procedure on the remote host
that will interact with your process over STDIN/STDOUT. This is a work around
for SSH Servers that don't support subsystems.

=over 4

=item B<$command>

The command to run on the remote system.

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

=head1 MUTATORS

=head2 eol

Sets the EOL for commands. Defaults to LF - "\012".

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
