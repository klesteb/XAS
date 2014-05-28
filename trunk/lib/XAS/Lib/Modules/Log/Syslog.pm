package XAS::Lib::Modules::Log::Syslog;

our $VERSION = '0.01';

use Params::Validate 'HASHREF';
use Sys::Syslog ':DEFAULT setlogsock';

use XAS::Class
  base       => 'XAS::Base',
  version    => $VERSION,
  mixins     => 'init_log output destroy',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub output {
    my $self  = shift;

    $self = $self->prototype() unless ref $self;

    my $args = $self->validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $priority = _translate($args->{priority});
    my $message = sprintf('%s', $args->{message});

    syslog($priority, $message);

}

sub destroy {
    my $self = shift;

    closelog();

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _translate {
    my $value = shift;

    my $translate = {
        info  => 'info',
        error => 'err',
        warn  => 'warning',
        fatal => 'alert',
        trace => 'notice',
        debug => 'debug'
    };

    return $translate->{lc($value)};

}

sub init_log {
    my $self = shift;

    setlogsock('unix');
    openlog($self->process, 'pid', $self->facility);

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
