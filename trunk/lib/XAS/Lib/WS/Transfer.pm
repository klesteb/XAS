package XAS::Lib::WS::Transfer;

our $VERSION = '0.01';

use Try::Tiny;
use Params::Validate qw ( SCALAR );

use XAS::Class
  version => $VERSION,
  base    => 'XAS::Lib::WS::RemoteShell',
  codecs  => 'base64 unicode',
  utils   => 'dotid',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub get {
    my $self = shift;
    my $p = validate_params(\@_, {
        -local  => { type => SCALAR },
        -remote => { type => SCALAR },
    });

    my $local  = $p->{'-local'};
    my $remote = $p->{'-remote'};

    # this assumes that the remote WS-Manage server is Microsoft based

    my $fh;
    my $code   = $self->_code_get_powershell($remote);
    my $invoke = "powershell -noprofile -encodedcommand $code";

    try {

        if ($self->create) {

            $self->command($invoke);
            $self->receive();

            if (($self->exitcode == 0) && ($self->stderr eq '')) {

                if (open($fh, '>', $local)) {

                    print $fh decode_base64($self->stdout);
                    close $fh;

                } else {

                    $self->throw_msg(
                        dotid($self->class) . '.put.badfile',
                        'file_create',
                        $local, $!
                    );

                }

            } else {

                $self->throw_msg(
                    dotid($self->class) . '.put.badrc',
                    'ws_badrc',
                    $self->exitcode,
                    $self->stdout
                );

            }

            $self->destroy();

        } else {

            $self->throw_msg(
                dotid($self->class) . '.get.noshell',
                'ws_noshell',
            );

        }

    } catch {

        my $ex = $_;
        $self->destroy();
        die $ex;

    };

}

sub put {
    my $self = shift;
    my $p = validate_params(\@_, {
        -local  => { type => SCALAR },
        -remote => { type => SCALAR },
    });

    my $local  = $p->{'-local'};
    my $remote = $p->{'-remote'};

    # this assumes that the remote WS-Manage server is Microsoft based

    my $fh;
    my $size   = 30 * 57;
    my $invoke = 'powershell -noprofile -encodedcommand %s';

    try {

        if ($self->create) {

            if (open($fh, '<', $local)) {

                while (read($fh, my $buf, $size)) {

                    my $data = encode_base64($buf, '');
                    my $code = $self->_code_put_powershell($remote, $data);
                    my $cmd  = sprintf($invoke, $code);

                    $self->command($cmd);
                    $self->receive();

                    if ($self->exitcode != 0) {

                        $self->throw_msg(
                            dotid($self->class) . '.put.badrc',
                            'ws_badrc',
                            $self->exitcode,
                            $self->stdout
                        );

                    }

                }

                close $fh;

            } else {

                $self->throw_msg(
                    dotid($self->class) . '.put.badfile',
                    'file_create',
                    $local, $!
                );

            }

            $self->destroy();

        } else {

            $self->throw_msg(
                dotid($self->class) . '.get.noshell',
                'ws_noshell',
            );

        }

    } catch {

        my $ex = $_;
        $self->destroy();
        die $ex;

    };

}

sub exists {
    my $self = shift;
    my $path = validate_params(\@_, [1]);

    my $code   = $self->_code_exists_powershell($path);
    my $invoke = "powershell -noprofile -encodedcommand $code";

    try {

        if ($self->create) {

            $self->command($invoke);
            $self->receive();
            $self->destroy();

        } else {

            $self->throw_msg(
                dotid($self->class) . '.get.noshell',
                'ws_noshell',
            );

        }

    } catch {

        my $ex = $_;
        $self->destroy();
        die $ex;

    };

    return $self->exitcode;

}

sub mkdir {
    my $self = shift;
    my $path = validate_params(\@_, [1]);

    my $code   = $self->_code_mkdir_powershell($path);
    my $invoke = "powershell -noprofile -encodedcommand $code";

    try {

        if ($self->create) {

            $self->command($invoke);
            $self->receive();
            $self->destroy();

        } else {

            $self->throw_msg(
                dotid($self->class) . '.get.noshell',
                'ws_noshell',
            );

        }

    } catch {

        my $ex = $_;
        $self->destroy();
        die $ex;

    };

    return $self->exitcode;

}

sub rmdir {
    my $self = shift;
    my $path = validate_params(\@_, [1]);

    my $code   = $self->_code_rmdir_powershell($path);
    my $invoke = "powershell -noprofile -encodedcommand $code";

    try {

        if ($self->create) {

            $self->command($invoke);
            $self->receive();
            $self->destroy();

        } else {

            $self->throw_msg(
                dotid($self->class) . '.get.noshell',
                'ws_noshell',
            );

        }

    } catch {

        my $ex = $_;
        $self->destroy();
        die $ex;

    };

    return $self->exitcode;

}

sub delete {
    my $self = shift;
    my $path = validate_params(\@_, [1]);

    my $code   = $self->_code_del_powershell($path);
    my $invoke = "powershell -noprofile -encodedcommand $code";

    try {

        if ($self->create) {

            $self->command($invoke);
            $self->receive();
            $self->destroy();

        } else {

            $self->throw_msg(
                dotid($self->class) . '.get.noshell',
                'ws_noshell',
            );

        }

    } catch {

        my $ex = $_;
        $self->destroy();
        die $ex;

    };

    return $self->exitcode;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Powershell Boilerplate - yeah heredoc...
#
# some powershell code borrowed from
#    https://github.com/WinRb/winrm-fs/tree/master/lib/winrm-fs/scripts
# ----------------------------------------------------------------------

sub _code_put_powershell {
    my $self     = shift;
    my $filename = shift;
    my $data     = shift;

    my $code = <<'CODE';
$ProgressPreference='SilentlyContinue'
try {
    $data = '__DATA__'
    $bytes = [System.Convert]::FromBase64String($data)
    $file = [System.IO.File]::Open('__FILENAME__', 'Append')
    $file.Write($bytes, 0, $bytes.Length)
    $file.Close()
    exit 0
} catch {
    Write-Output $_.Exception.Message
    exit 1
}
CODE

    $code =~ s/__FILENAME__/$filename/;
    $code =~ s/__DATA__/$data/;

    return encode_base64(encode_unicode('UTF-16LE', $code), '');

}

sub _code_get_powershell {
    my $self = shift;
    my $filename = shift;

my $code = <<'CODE';
$ProgressPreference='SilentlyContinue'
$p = $ExecutionContext.SessionState.Path
$path = $p.GetUnresolvedProviderPathFromPSPath("__FILENAME__")
if (Test-Path $path -PathType Leaf) {
    $bytes = [System.convert]::ToBase64String([System.IO.File]::ReadAllBytes($path))
    Write-Host $bytes
    exit 0
}
Write-Host 'File not found'
exit 1
CODE

    $code =~ s/__FILENAME__/$filename/;

    return encode_base64(encode_unicode('UTF-16LE', $code), '');

}

sub _code_exists_powershell {
    my $self = shift;
    my $path = shift;

my $code = <<'CODE';
$ProgressPreference='SilentlyContinue'
$p = $ExecutionContext.SessionState.Path
$path = $p.GetUnresolvedProviderPathFromPSPath('__PATH__')
if (Test-Path $path) {
    exit 0
} else {
    exit 1
}
CODE

    $code =~ s/__PATH__/$path/;

    return encode_base64(encode_unicode('UTF-16LE', $code), '');

}

sub _code_mkdir_powershell {
    my $self = shift;
    my $path = shift;

my $code = <<'CODE';
$ProgressPreference='SilentlyContinue'
$p = $ExecutionContext.SessionState.Path
$path = $p.GetUnresolvedProviderPathFromPSPath('__PATH__')
if (!(Test-Path $path)) {
    New-Item -ItemType Directory -Force -Path $path | Out-Null
    exit 0
}
Write-Host "__PATH__ not found"
exit 1
CODE

    $code =~ s/__PATH__/$path/g;

    return encode_base64(encode_unicode('UTF-16LE', $code), '');

}

sub _code_rmdir_powershell {
    my $self = shift;
    my $path = shift;

my $code = <<'CODE';
$ProgressPreference='SilentlyContinue'
$p = $ExecutionContext.SessionState.Path
$path = $p.GetUnresolvedProviderPathFromPSPath('__PATH__')
if (Test-Path $path) {
    Remove-Item $path -Force
    exit 0
}
Write-Host "__PATH__ not found"
exit 1
CODE

    $code =~ s/__PATH__/$path/g;

    return encode_base64(encode_unicode('UTF-16LE', $code), '');

}

sub _code_del_powershell {
    my $self = shift;
    my $path = shift;

my $code = <<'CODE';
$ProgressPreference='SilentlyContinue'
$p = $ExecutionContext.SessionState.Path
$path = $p.GetUnresolvedProviderPathFromPSPath('__PATH__')
if (Test-Path $path) {
    Remove-Item $path -Force
    exit 0
}
Write-Host "__PATH__ not found"
exit 1
CODE

    $code =~ s/__PATH__/$path/g;

    return encode_base64(encode_unicode('UTF-16LE', $code), '');

}

1;

__END__

=head1 NAME

XAS::Lib::WS::Transfer - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Lib::WS::Transfer;

 my $trans = XAs::Lib::WS::Transfer->new(
   -username    => 'Administrator',
   -password    => 'secret',
   -url         => 'http://windowserver:5985/wsman',
   -auth_method => 'basic',
   -keep_alive  => 1,
 );

 unless ($trans->exists('test.txt')) {

    $trans->put(-local => 'junk.txt', -remote => 'test.txt');

 }

=head1 DESCRIPTION

This package implements a crude method of interacting with a Windows based
WS-Manage server, at the file system level. The only way to interact is thru 
issuing commands. You can not interact with those commands. Even thou there 
are hints within the Microsoft documentation about duplex communications, they 
don't seem to work for this purpose. It would be nice, to be able to interact,
with that newly created command shell. Somethings would be so much easier.

=head1 METHODS

=head2 new

This module inherits from L<XAS::Lib::WS::RemoteShell|XAS::Lib::WS::RemoteShell> and
takes the same parameters.

=head2 get(...)

Retrieve a file from the remote server. This is very memory intensive 
operation as the file is converted to base64 and dumped to stdout on the 
remote end. This blob is then buffered on the local side and converted back
to a binary blob before being written out to disk. This method can be used 
to transfer binary files. It takes these parameters:

=over 4

=item B<-local>

The name of the local file. Paths are not checked and any existing file
will be over written.

=item B<-remote>

The name of the remote file. 

=back

=head2 put(...)

This method will put a file on the remote server. This is an extremely slow 
operation. The local file is block read and the buffer is converted to
base64. This buffer is then stored within a script that will be executed to 
convert the blob back into a binary stream. This stream is then appended to 
the remote file. Not recommeded for large files. This method can be used to 
transfer binary files. It takes these parameters:

=over 4

=item B<-local>

The name of the local file.

=item B<-remote>

The name of the remote file. Paths are not checked and any existing file 
will be appended too.

=back

=head2 exists($path)

This method checks to see if the remote path exists. Returns true if it does.

=over 4

=item B<$path>

The name of the path.

=back

=head2 delete($filename)

This method will delete a remote file. Returns true if successfull.

=over 4

=item B<$filename>

The name of the file to delete.

=back

=head2 mkdir($path)

This method will create a directory on the remote server. Intermediate 
directories are also created. Returns true if successful.

=over 4

=item B<$path>

The path for the directory.

=back

=head2 rmdir($path)

This method will remove a directory for the the remote server. Returns
true if successful.

=over 4

=item B<$path>

The name of the directory to remove.

=back

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut