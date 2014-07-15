package XAS::Exception;

use base Badger::Exception;
$Badger::Exception::TRACE = 1;

sub stack_trace {
    my $self = shift;

    my @lines;

    if (my $stack = $self->{ stack }) {

        foreach my $caller (@$stack) {

            # ignore Try::Tiny lines

            next if (grep( $_ =~ /Try::Tiny/, @$caller ));
            push(@lines, $self->message( caller => @$caller ));

        }

    }

    return join("\n", @lines);

}

1;

__END__

=head1 NAME

XAS::Exception - The base exception class for the XAS environment

=head1 DESCRIPTION

This module defines a base exception class for the XAS Environment and 
inherits from L<Badger::Exception|http://badgerpower.com/docs/Badger/Exception.html>. 
The only differences is that it turns stack tracing on by default.

=head1 METHODS

=head2 stack_trace

Removes any reference to Try::Tiny in the stack trace.

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
