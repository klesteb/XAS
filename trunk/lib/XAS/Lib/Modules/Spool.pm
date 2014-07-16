package XAS::Lib::Modules::Spool;

our $VERSION = '0.03';

use Try::Tiny;
use XAS::Factory;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  mixin     => 'XAS::Lib::Mixins::Handlers',
  accessors => 'lockmgr',
  utils     => 'dotid',
  vars => {
    PARAMS => {
      -directory => { isa => 'Badger::Filesystem::Directory' }, 
      -mask      => { optional => 1, default => 0664 },
      -extension => { optional => 1, default => '.pkt' },
      -seqfile   => { optional => 1, default => '.SEQ' },
      -lockfile  => { optional => 1, default => 'spool' },
    }
  }
;

# ------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------

sub read {
    my $self = shift;

    my ($filename) = $self->validate_params(\@_, [
        { isa => 'Badger::Filesystem::File' },
    ]);

    my $packet;

    if ($self->lockmgr->lock_directory($self->directory)) {

        $packet = $self->read_packet($filename);
        $self->lockmgr->unlock_directory($self->directory);

    } else { 

        $self->throw_msg(
            dotid($self->class) . '.read.lock_error',
            'lock_error', 
            $self->directory->path
        );

    }

    return $packet;

}

sub write {
    my $self = shift;

    my ($packet) = $self->validate_params(\@_, [ 1 ]);

    my $seqnum;

    if ($self->lockmgr->lock_directory($self->directory)) {

        $seqnum = $self->sequence();

        $self->write_packet($packet, $seqnum);
        $self->lockmgr->unlock_directory($self->directory);

    } else { 

        $self->throw_msg(
            dotid($self->class) . '.write.lock_error', 
            'lock_error', 
            $self->directory->path
        ); 

    }

    return 1;

}

sub scan {
    my $self = shift;

    my @files;
    my $pattern = qr/$self->extension/i;

    if ($self->lockmgr->lock_directory($self->directory)) {

        @files = sort(grep( $_->path =~ /$pattern/, $self->directory->files() ));
        $self->lockmgr->unlock_directory($self->directory);

    } else {

        $self->throw_msg(
            dotid($self->class) . '.scan.lock_error',
            'lock_error',
            $self->directory->path
        );

    }

    return @files;

}

sub delete {
    my $self = shift;

    my ($file) = $self->validate_params(\@_, [
        { isa => 'Badger::Filesystem::File' },
    ]);

    if ($self->lockmgr->lock_directory($self->directory)) {

        try {

            $file->delete;

        } catch {

            my $ex = $_;

            $self->exception_handler($ex);

        };

        $self->lockmgr->unlock_directory($self->directory);

    } else { 

        $self->throw_msg(
            dotid($self->class) . '.delete.lock_error', 
            'lock_error', 
            $self->directory->path
        ); 

    }

}

sub count {
    my $self = shift;

    my @files;
    my $count;
    my $pattern = qr/$self->extension/i;

    if ($self->lockmgr->lock_directory($self->directory)) {

        @files = grep( $_->path =~ /$pattern/, $self->directory->files() );
        $count = scalar(@files);

        $self->lockmgr->unlock_directory($self->directory);

    } else {

        $self->throw_msg(
            dotid($self->class) . '.count.lock_error',
            'lock_error',
            $self->directory->path
        );

    }

    return $count;

}

sub get {
    my $self = shift;

    my @files;
    my $filename;
    my $pattern = qr/$self->extension/i;

    if ($self->lockmgr->lock_directory($self->directory)) {

        @files = sort(grep( $_->path =~ /$pattern/, $self->directory->files() ));
        $filename = $files[0];

        $self->lockmgr->unlock_directory($self->directory);

    } else {

        $self->throw_msg(
            dotid($self->class) . '.get.lock_error',
            'lock_error',
            $self->directory->path
        );

    }

    return $filename;

}

# ------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{lockmgr} = XAS::Factory->module('lockmgr', {
        -lockfile => $self->lockfile
    });
    
    return $self;

}

sub sequence {
    my $self = shift;

    my $fh;
    my $cnt;
    my $seqnum;
    my $mask = $self->mask + 0;
    my $file = File($self->directory, $self->seqfile);

    try {

        if ($file->exists) {

            $fh = $file->open("r+");
            $seqnum = $fh->getline;
            $seqnum++;
            $fh->seek(0, 0);
            $fh->print($seqnum);
            $fh->close;

        } else {

            $fh = $file->open("w");
            $fh->print("1");
            $fh->close;

            $cnt = chmod($mask, $file);
            $self->throw_msg(
                dotid($self->class) . '.sequence.invperms', 
                'invperms', 
                $file
            ) if ($cnt < 1);

            $seqnum = 1;

        }

    } catch {

        my $ex = $_;

        $self->throw_msg(
            dotid($self->class) . '.sequence', 
            'sequence', 
            $file
        );

    };

    return $seqnum;

}

sub write_packet {
    my $self = shift;

    my ($packet, $seqnum) = $self->validate_params(\@_, [1,1]);

    my $fh;
    my $cnt;
    my $mask = $self->mask + 0;
    my $file = File($self->directory, $seqnum . $self->extension);

    try {

        $fh = $file->open("w");
        $fh->print($packet);
        $fh->close;
        $cnt = chmod($mask, $file->path) or 
          $self->throw_msg(
              dotid($self->class) . '.write_packet.invperms',
              'invperms',
              $file->path
          );

    } catch {

        my $ex = $_;

        $self->throw_msg(
            dotid($self->class) . '.write_packet', 
            'write_packet', 
            $file->path
        );

    };

}

sub read_packet {
    my $self = shift;

    my ($file) = $self->validate_params(\@_, [
        { isa => 'Badger::Filesystem::File' }
    ]);

    my $fh;
    my $packet;

    try {

        $fh = $file->open("r");
        $packet = $fh->getline;
        $fh->close;

    } catch {

        my $ex = $_;

        $self->throw_msg(
            dotid($self->class) . '.read_packet', 
            'read_packet', 
            $file->path
        );

    };

    return $packet;

}

1;

__END__

=head1 NAME

XAS::Lib::Modules::Spool - A Perl extension for the XAS environment

=head1 SYNOPSIS

 use XAS::Factory;

 my $spl = XAS::Factory->module(
     spool => {
         -directory => 'spool'
     }
 );

 $spl->write('this is some data');
 $spl->write("This is some other data");

 my @files = $spl->scan();

 foreach my $file (@files) {

    my $packet = $spl->read($file);
    print $packet;
    $spl->delete($file);

 }

=head1 DESCRIPTION

This module provides the basic handling of spool files. This module 
provides basic read, write, scan and delete functionality for those files. 

This functionality is designed to be overridden with more specific methods 
for each type of spool file required. 

Individual spool files are stored in sub directories. Since multiple 
processes may be accessing those directories, lock files are being used to 
control access. This is an important requirement to prevent possible race 
conditions between those processes.

A sequence number is stored in the .SEQ file within each sub directory. Each 
spool file will use the ever increasing sequence number as the file name with 
a .pkt extension. To reset the sequence number, just delete the .SEQ file. A 
new file will automatically be created.

=head1 METHODS

=head2 new

This will initialize the base object. It takes the following parameters:

=over 4

=item B<-directory>

This is the directory to use for spool files.

=item B<-lockfile>

The name of the lock file to use. Defaults to 'spool'.

=item B<-extension>

The extension to use on the spool file. Defaults to '.pkt'.

=item B<-seqfile>

The name of the sequence file to use. Defaults to '.SEQ'.

=item B<-mask>

The file permissions for any created file. Default 0664.

=back

=head2 write($packet)

This will write a new spool file using the supplied "packet". Each
evocation of write() will create a new spool file. This method should be 
overridden by the more specific needs of sub classes.

=over 4

=item B<$packet>

The data that will be written to the spool file.

=back

=head2 read($filename)

This will read the contents of spool file and return a data structure. This 
method should be overridden by the more specific needs of sub classes.

Example

    $packet = $spl->read($file);

=head2 scan

This will scan the spool directory looking for items to process. It returns
and array of files to process.

=head2 delete($filename)

This method will delete the file from the spool directory.

=head2 count

This method will return a count of the items in the spool directory.

=head2 get

This method will retrieve a file name from the spool directory.

=head1 ACCESORS

=head2 extension

This method will get the current file extension.

=head2 lockfile

This method will get the current lock file name.

=head2 segfile

This method will get the current sequence file name.

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
