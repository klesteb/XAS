package XAS::Lib::Batch;

our $VERSION = '0.01';

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  utils   => 'dotid run_cmd trim',
  vars => {
    PARAMS => {
      -interface => { optional => 1, default => 'XAS::Lib::Batch::Interface::Torque' },
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub do_cmd {
    my $self = shift;
    my ($cmd, $sub) = $self->validate_params(\@_, [1,1]);

    $self->log->debug("command = $cmd");

    my ($output, $rc, $sig) = run_cmd($cmd);

    if ($rc != 0) {

        my $msg = $output->[0] || '';

        $self->throw_msg(
            dotid($self->class) . ".$sub",
            'pbserr',
            $rc, trim($msg)
        );

    }

    return $output;

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->class->mixin($self->interface);

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

Copyright (c) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
