package XAS::Lib::Modules::Log::Console;

our $VERSION = '0.01';

use Params::Validate 'HASHREF';
use XAS::Class
  base      => 'XAS::Base',
  version   => $VERSION,
  mixins    => 'init_log output',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub output {
    my $self  = shift;

    $self = $self->prototype() unless ref $self;

    my ($args) = $self->validate_params(\@_, [
        { type => HASHREF }
    ]);

    warn sprintf("%-5s - %s\n", 
        uc($args->{priority}), 
        $args->{message}
    );

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init_log {
    my $self = shift;
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

Copyright (C) 2014 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
