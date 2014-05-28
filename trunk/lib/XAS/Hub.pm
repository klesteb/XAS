package XAS::Hub;

our $VERSION = '0.01';

use XAS::Class
  debug    => 0,
  version  => $VERSION,
  base     => 'XAS::Base',
  auto_can => '_auto_load',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _auto_load {
    my $self = shift;
    my $name = shift;

    if ($name eq 'alert') {

        return sub { XAS::Factory->module('alert'); } 

    }

    if ($name eq 'alerts') {

        return sub { XAS::Alerts->new(); } 

    }

    if ($name eq 'env') {

        return sub { XAS::Factory->module('environment'); } 

    }

    if ($name eq 'email') {

        if ( my $params = $self->class->any_var('EMAIL')) {

            return sub { XAS::Factory->module('email', $params); } 

        } else {

            return sub { 

                XAS::Factory->module('email', {
                    -server => $self->env->mxserver,
                    -port   => $self->env->mxport,
                    -mailer => $self->env->mxmailer
                }); 

            }

        }

    }

    if ($name eq 'log') {

        if ( my $params = $self->class->any_var('LOG')) {

            return sub { XAS::Factory->module('logger', $params); } 

        } else {

            return sub { 

                XAS::Factory->module('logger', {
                    -filename => $self->env->logfile,
                    -type     => $self->env->logtype,

                }); 

            }

        }

    }

    $self->throw_msg(
        dotid($self->class) . '.auto_load.invmethod',
        'invmethod',
        $name
    );

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
