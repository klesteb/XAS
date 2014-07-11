package XAS::Lib::Curses::Unix;

our $VERSION = '0.01';

use POE;
use Curses;
use POE::Wheel::Curses;
use Params::Validate qw(SCALAR ARRAYREF HASHREF CODEREF GLOB GLOBREF SCALARREF HANDLE BOOLEAN UNDEF validate validate_pos);

use XAS::Class
  version => $VERSION,
  base    => 'XAS::Base',
  mixins  => 'startup keyin @button_events',
;

Params::Validate::validation_options(
    on_fail => sub {
        my $params = shift;
        my $class  = __PACKAGE__;
        XAS::Base::validation_exception($params, $class);
    }
);

our @button_events = qw(
    BUTTON1_PRESSED BUTTON1_RELEASED BUTTON1_CLICKED
    BUTTON1_DOUBLE_CLICKED BUTTON1_TRIPLE_CLICKED
    BUTTON2_PRESSED BUTTON2_RELEASED BUTTON2_CLICKED
    BUTTON2_DOUBLE_CLICKED BUTTON2_TRIPLE_CLICKED
    BUTTON3_PRESSED BUTTON3_RELEASED BUTTON3_CLICKED
    BUTTON3_DOUBLE_CLICKED BUTTON3_TRIPLE_CLICKED
    BUTTON4_PRESSED BUTTON4_RELEASED BUTTON4_CLICKED
    BUTTON4_DOUBLE_CLICKED BUTTON4_TRIPLE_CLICKED
    BUTTON5_PRESSED BUTTON5_RELEASED
    BUTTON5_CLICKED BUTTON5_DOUBLE_CLICKED BUTTON5_TRIPLE_CLICKED
    BUTTON_SHIFT BUTTON_CTRL BUTTON_ALT
);

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub startup {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    
    # now listen to the keys
    $heap->{console} = POE::Wheel::Curses->new(
        InputEvent => 'key_handler',
    );

}

sub keyin {
    my ($kernel) = $_[KERNEL];
 
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

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See L<http://dev.perl.org/licenses/> for more information.

=cut
