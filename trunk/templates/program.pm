package XAS::Apps:: ;

our $VERSION = '0.01';

use Params::Validate ':all';

use XAS::Class
  base    => 'XAS::Base',
  version => $VERSION,
  vars => {
    PARAMS => {
    }
  }
;

Params::Validate::validation_options(
    on_fail => sub {
        my $params = shift;
        my $class  = __PACKAGE__;
        XAS::Base::validation_exception($params, $class);
    }
);

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub setup {
    my $self = shift;

}

sub main {
    my $self = shift;

    $self->setup();
    
}

sub options {
    my $self = shift;

    my $options = $self->SUPER::options();

    return $options;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Apps;

=head1 DESCRIPTION

=head1 METHODS

=head2 setup

=head2 main

=head2 options

=head1 SEE ALSO

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
