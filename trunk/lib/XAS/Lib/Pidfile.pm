package XAS::Lib::PidFile;

our $VERSION = '0.01';

my $mixin;

BEGIN {
    $mixin = 'XAS::Lib::PidFile::Unix';
    $mixin = 'XAS::Lib::PidFile::Win32' if ($^O eq 'MSWin32');
}

use XAS::Lib::Modules::Locking;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  mixin     => $mixin,
  utils     => 'trim dotid',
  accessors => 'env lockmgr',
  vars => {
    PARAMS => {
      pid  => { optional => 1, default => $$ },
      file => { optional => 1, default => undef, isa => 'Badger::Filesystem::File' },
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub write {
    my $self = shift;

    my $stat = 0;
    my $lock = $self->file->directory;
    my $output = sub {

        my $fh = $self->file->open('w');
        $fh->printf("%s\n", $self->pid);
        $fh->close;

    };

    if ($self->lockmgr->lock_directory($lock)) {

        if ($self->file->exists) {

            $output->();

        } else {

            $self->file->create();
            $output->();

        }

        $stat = 1;
        $self->lockmgr->unlock_directory($lock);

    }

    return $stat;

}

sub remove {
    my $self = shift;

    my $lock = $self->file->directory;

    if ($self->lockmgr->lock_directory($lock)) {

        $self->file->delete() if ($self->file->exists);
        $self->lockmgr->unlock_directory($lock);

    }

}


# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _get_pid {
    my $self = shift;

    my $pid = undef;
    my $lock = $self->file->directory;

    if ($self->lockmgr->lock_directory($lock)) {

        if ($self->file->exists) {

            my $fh = $self->file->open();
            $pid = $fh->getline();
            $pid = trim($pid);
            $fh->close();

        }

        $self->lockmgr->unlock_directory($lock);

    }

    return $pid

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{lockmgr} = XAS::Lib::Modules::Locking->new();

    unless (defined($self->{file})) {

        $self->{file} = $self->env->pidfile;

    }

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::PidFile - A class to manage pid files within XAS

=head1 SYNOPSIS

  use XAS::Lib::PidFile;

  my $pid = XAS::Lib::PidFile->new(
      -file => File('/', 'var', 'run', 'xas', 'process.pid')
  );

  if ($pid->is_running) {

      printf("already running\n");
      exit 2;

  }

  $pid->write();
  
  ...
  
  $pid->remove();
  
=head1 DESCRIPTION

This class will manage pid files for XAS. It loads mixins for individual
platforms to help with determining if a process is already running. It
uses discretionary directory locking to control access to the pid files.

=head1 METHODS

=head2 new

This method initialize the module and takes this optional parameters.

=over 4

=item B<-file>

Specifiy a pid file to use. This defaults to the pid file defined by
L<XAS::Lib::Modules::Environment> for the current procedure.

=item B<-pid>

Define a pid number. Defaults to the pid of the current process.

=back

=head2 is_running

This method is loaded thru a mixin. It will attempt to load a currently
existing pid file and check to see if that pid is active and if that
running process is the same as the current procedure.

If it is, then it will return true. If not then it will return false.

=head2 write

Write the current pid to the pid file.

=head2 remove

Remove the current pid file.

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
