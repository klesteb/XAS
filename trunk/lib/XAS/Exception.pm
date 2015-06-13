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
inherits from L<Badger::Exception|https://metacpan.org/Badger::Exception>. 
The only differences is that it turns stack tracing on by default.

=head1 METHODS

=head2 stack_trace

Removes any reference to L<Try::Tiny|https://metacpan.org/pod/Try::Tiny> in the stack trace.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
