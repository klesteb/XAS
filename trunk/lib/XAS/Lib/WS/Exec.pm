package XAS::Lib::WS::Exec;

our $VERSION = '0.01';

use Try::Tiny;

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Lib::WS::RemoteShell',
  utils     => ':validation trim',
  constants => 'SCALAR CODEREF',
  vars => {
    PARAMS => {
      -eol         => { optional => 1, default => "\015\012" },        
      -keep_alive  => { optional => 1, default => 1 },
      -auth_method => { optional => 1, default => 'basic', regex => qr/any|noauth|basic|digest|ntlm|negotiate/ },
    }
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub connect {
	my $self = shift;

	$self->create();

}

sub disconnect {
	my $self = shift;

	$self->destroy();

}

sub setup {
    my $self = shift;

    # do nothing

}

sub run {
    my $self = shift;
    my ($command) = validate_parans(\@_, [1]);

    # do nothing

}

sub exit_signal {
    my $self = shift;
    return 0;
}

sub call {
    my $self = shift;
    my ($command, $parser) = validate_params(\@_, [
       { type => SCALAR },
       { type => CODEREF },
    ]);

    my @output;
    my $eol = $self->eol;

    # execute a command, retrieve the output and dispatch to a parser.

    try {

        $self->command($command);
        $self->receive();
        $self->check_exit_code();

        @output = map { trim($_) } split($eol, $self->stdout);

    } catch {

        my $ex = $_;
        $self->destroy();
        die $ex;

    };

    return $parser->(\@output);

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

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
