package XAS::Lib::Modules::Locking;

our $VERSION = '0.02';

use XAS::Factory;
use LockFile::Simple;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Base',
  accessors  => 'lockmgr',
  mutators   => 'lockfile max delay hold',
  filesystem => 'File',
  vars => {
    PARAMS => {
      -lockfile => { optional => 1, default => 'locked' },
      -max      => { optional => 1, default => 20 },
      -delay    => { optional => 1, default => 1 },
      -hold     => { optional => 1, default => 900 },
    }
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub lock_directory {
    my $self = shift;

    my ($path) = $self->validate_params(\@_, [
        { isa => 'Badger::Filesystem::Directory' },
    ]);

    my $lock = $self->lock_file_name($path);

    return $self->lockmgr->lock($lock);

}

sub unlock_directory {
    my $self = shift;

    my ($path) = $self->validate_parms(\@_, [
        { isa => 'Badger::Filesystem::Directory' },
    ]);

    my $lock = $self->lock_file_name($path);

    $self->lockmgr->unlock($lock);

}

sub lock_directories {
    my $self = shift;

    my ($sdir, $ddir) = $self->validate_params(\@_, [
        { isa => 'Badger::Filesystem::Directory' },
        { isa => 'Badger::Filesystem::Directory' },
    ]);

    my $stat = 0;

    if ($self->lock_directory($sdir)) {

        if ($self->lock_directory($ddir)){

            $stat = 1;

        } else {

            $self->unlock_directory($sdir);

        }

    }

    return $stat;

}

sub unlock_directories {
    my $self = shift;

    my ($sdir, $ddir) = $self->validate_params(\@_, [
        { isa => 'Badger::Filesystem::Directory' },
        { isa => 'Badger::Filesystem::Directory' },
    ]);

    $self->unlock_directory($sdir);
    $self->unlock_directory($ddir);

}

sub lock_file_name {
    my $self = shift;

    my ($directory) = $self->validate_params(\@_, [
        { isa => 'Badger::Filesystem::Directory' },
    ]);

    my $lock = File($directory->canonical, $self->lockfile);

    return $lock->path;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{lockmgr} = LockFile::Simple->make(
        -stale  => 1,
        -nfs    => 1,
        -format => '%f.lck',
        -max    => $self->max,
        -hold   => $self->hold,
        -delay  => $self->delay,
        -wfunc  => sub { my $msg = shift; $self->log->warn($msg); },
        -efunc  => sub { my $msg = shift; $self->log->error($msg); }
    );

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Modules::Locking - A module to provide discretionary directory locking.

=head1 SYNOPSIS

 package My::App;

 use XAS::Class
    version   => '0.01',
    base      => 'XAS::Lib::App',
 ;

 sub main {

    if ($self->lockmgr->lock_directories('here', 'there')) {

        $self->lockmgr->unlock_directories('here', 'there);

    }

 }
 
 1;

=head1 DESCRIPTION

This module provides discretionary directory locking. This is used to 
coordinate access to shared resources. It is implemented as a singleton. 
This module will also auto-load if "lockmgr" is used as a method invocation.

=head1 METHODS

=head2 new($parameters)

This method initializes the module. It takes these parameters:

=over 4

=item B<-lockfile>

The optional name of the lock file. It defaults to "locked".

=item B<-max>

The optional number of retries. This defaults to 20.

=item B<-delay>

The number of seconds to delay before retrying to acquire the lock. This
defaults to 1 second.

=item B<-hold>

The amount of time to hold a lock. After this time the lock is considered 
"stale". This defaults to 900 seconds.

=back

=head2 lock_directory($directory)

This method will lock a single directory. It takes these parameters:

=over 4

=item B<$directory>

The directory to use when locking.

=back

=head2 unlock_directory($directory)

This method will unlock a single directory. It takes these parameters:

=over 4

=item B<$directory>

The directory to use when unlocking.

=back

=head2 lock_directories($source, $destination)

This method will attempt to lock the source and destination directories.
It takes these parameters:

=over 4

=item B<$source>

The source directory.

=item B<$destination>

The destination directory.

=back

=head2 unlock_directories($source, $destination)

This method will unlock the source and destination directories. It takes
these parameters:

=over 4

=item B<$source>

The source directory.

=item B<$destination>

The destination directory.

=back

=head2 lock_file_name($directory)

This method returns the locks file name. It can be overridden if needed.
The default name is 'locked'. It takes the following parameters:

=over 4

=item B<$directory>

The directory the lock file resides in.

=back

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
