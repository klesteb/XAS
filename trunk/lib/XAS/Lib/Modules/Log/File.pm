package XAS::Lib::Modules::Log::File;

our $VERSION = '0.01';

use XAS::Class
  debug    => 0,
  version  => $VERSION,
  base     => 'XAS::Base',
  utils    => 'dotid',
  mixins   => 'init_log log',
  messages => {
    invperms  => "unable to change file permissions on %s",
    creatfile => "unable to create file %s"
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub log {
    my $self  = shift;

    $self = $self->prototype() unless ref $self;

    my ($level, $message) = $self->validate_params(\@_, [
        { regex => $levels },
        1
    ]);

    my $output = $self->_generate($level, $message);

    $self->filename->append(
        sprintf("[%s] %-5s - %s\n", 
            $output->{datetime}->strftime('%Y-%m-%d %H:%M:%S'),
            uc($output->{priority}), 
            $output->{message}
    ));

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init_log {
    my $self = shift;

    # check to see if the file exists, otherwise create it

    unless ($self->filename->exists) {

        if (my $fh = $self->filename->open('>')) {
                                    
            $fh->close;

        } else {

            $self->throw_msg(
                dotid($self->class) . '.init_log.creatfile',
                'creatfile', 
                $self->filename->path
            );

        }

    }

    # Change the file permissions to rw-rw-r, skip this on Windows 
    # as this will create a read only file.

    if ($^O ne "MSWin32") {

        my ($cnt, $mode, $permissions);

        # set file permissions

        $mode = ($self->filename->stat)[2];
        $permissions = sprintf("%04o", $mode & 07777);

        if ($permissions ne "0664") {

            $cnt = chmod(0664, $self->filename->path);
            $self->throw_msg(
                dotid($self->class) . '.init_log.invperms',
                'invperms', 
                $self->filename->path) if ($cnt < 1);

        }

    }

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
