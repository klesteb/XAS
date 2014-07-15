package XAS::Lib::Modules::Log::Console;

our $VERSION = '0.01';

use Params::Validate 'HASHREF';
use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base',
  mixins    => 'init_log output destroy',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub output {
    my $self  = shift;

    my ($args) = $self->validate_params(\@_, [
        { type => HASHREF }
    ]);

    warn sprintf("%-5s - %s\n", 
        uc($args->{priority}), 
        $args->{message}
    );

}

sub destroy {
    my $self = shift;

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

XAS::Lib::Modules::Log::Console - A mixin class for logging

=head1 DESCRIPTION

This module is a mixin for logging. It logs to stderr.

=head1 METHODS

=head2 init_log

This method initializes the module.

=head2 output($hashref)

The method formats the hashref and writes out the results.

=head2 destroy

This methods deinitializes the module.

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
