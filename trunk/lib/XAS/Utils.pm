package XAS::Utils;

our $VERSION = '0.06';

use DateTime;
use Try::Tiny;
use XAS::Exception;
use DateTime::Format::Pg;
use Digest::MD5 'md5_hex';
use Params::Validate ':all';
use DateTime::Format::Strptime;
use POSIX qw(:sys_wait_h setsid);

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'Badger::Utils',
  constants  => 'HASH ARRAY',
  filesystem => 'Dir File',
  exports => {
    all => 'db2dt dt2db trim ltrim rtrim daemonize hash_walk  
            load_module bool init_module load_module compress exitcode 
            kill_proc spawn _do_fork glob2regex dir_walk
            env_store env_restore env_create env_parse env_dump env_clear
            left right mid instr is_truthy is_falsey run_cmd
            validate_params validation_exception',
    any => 'db2dt dt2db trim ltrim rtrim daemonize hash_walk  
            load_module bool init_module load_module compress exitcode 
            kill_proc spawn _do_fork glob2regex dir_walk
            env_store env_restore env_create env_parse env_dump env_clear
            left right mid instr is_truthy is_falsey run_cmd
            validate_params validation_exception',
    tags => {
      dates      => 'db2dt dt2db',
      env        => 'env_store env_restore env_create env_parse env_dump env_clear',
      modules    => 'init_module load_module',
      strings    => 'trim ltrim rtrim compress left right mid instr',
      process    => 'daemonize spawn kill_proc exitcode _do_fork',
      boolean    => 'is_truthy is_falsey bool',
      validation => 'validate_params validation_exception',
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub validation_exception {
    my $param = shift;
    my $class = shift;

    my $format = 'invalid parameters passed, reason: %s';
    my $method = Badger::Utils::dotid($class) . '.invparams';

    $param = trim(lcfirst($param));

    my $ex = XAS::Exception->new(
        type => $method,
        info => Badger::Utils::xprintf($format, $param),
    );

    $ex->throw();

}

sub validate_params {
    my $params = shift;
    my $specs  = shift;
    my $class  = shift;

    unless (defined($class)) {

        $class = (caller(1))[3];

    }

    my $results = validate_with(
        params => $params,
        called => $class,
        spec   => $specs,
        normalize_keys => sub {
            my $key = shift; 
            $key =~ s/^-//; 
            return lc $key;
        },
        on_fail => sub {
            my $param = shift;
            validation_exception($param, $class);
        },
    );

    return wantarray ? @$results : $results;

}

# recursively walk a HOH
sub hash_walk {
    my $p = validate_params(\@_, {
        -hash     => { type => HASHREF }, 
        -keys     => { type => ARRAYREF }, 
        -callback => { type => CODEREF },
    });

    my $hash     = $p->{'hash'};
    my $key_list = $p->{'keys'};
    my $callback = $p->{'callback'};

    while (my ($k, $v) = each %$hash) {

        # Keep track of the hierarchy of keys, in case
        # our callback needs it.

        push(@$key_list, $k);

        if (ref($v) eq 'HASH') {

            # Recurse.

            hash_walk(-hash => $v, -keys => $key_list, -callback => $callback);

        } else {
            # Otherwise, invoke our callback, passing it
            # the current key and value, along with the
            # full parentage of that key.

            $callback->($k, $v, $key_list);

        }

        pop(@$key_list);

    }

}

# recursively walk a directory structure
sub dir_walk {
    my $p = validate_params(\@_, {
        -directory => { isa  => 'Badger::Filesystem::Directory' },
        -callback  => { type => CODEREF },
        -filter    => { optional => 1, default => qr/.*/, callbacks => {
            'must be a compiled regex' => sub {
                return (ref shift() eq 'Regexp') ? 1 : 0;
            }
        }},
    });

    my $folder   = $p->{'directory'};
    my $filter   = $p->{'filter'};
    my $callback = $p->{'callback'};

    my @files = grep ( $_->path =~ /$filter/, $folder->files() );
    my @folders = $folder->dirs;

    foreach my $file (@files) {

        $callback->($file);

    }

    foreach my $folder (@folders) {

        dir_walk(-directory => $folder, -filter => $filter, -callback => $callback);

    }

}

# Perl trim function to remove whitespace from the start and end of the string
sub trim {
    my ($string) = validate_params(\@_, [1]);

    $string =~ s/^\s+//;
    $string =~ s/\s+$//;

    return $string;

}

# Left trim function to remove leading whitespace
sub ltrim {
    my ($string) = validate_params(\@_, [1]);

    $string =~ s/^\s+//;

    return $string;

}

# Right trim function to remove trailing whitespace
sub rtrim {
    my ($string) = validate_params(\@_, [1]);

    $string =~ s/\s+$//;

    return $string;

}

# replace multiple whitspace with a single space
sub compress {
    my ($string) = validate_params(\@_, [1]);

    $string =~ s/\s+/ /gms;

    return $string;

}

# emulate Basics string function left()
sub left {
    my ($string, $offset) = validate_params(\@_, [1,1]);

    return substr($string, 0, $offset);

}

# emulate Basics string function right()
sub right {
    my ($string, $offset) = validate_params(\@_, [1,1]);

    return substr($string, -($offset));

}

# emulate Basics string function mid()
sub mid {
    my ($string, $start, $length) = validate_params(\@_, [1,1,1]);

    return substr($string, $start - 1, $length);

}

# emulate Basics string function instr()
sub instr {
    my ($start, $string, $compare) = validate_params(\@_, [1,1,1]);

    if ($start =~ /^[0-9\-]+/) {

        $start++;

    } else {

        $compare = $string;
        $string = $start;
        $start = 0;

    }

    return index($string, $compare, $start) + 1;

}

# Checks to see if the parameter is the string 't', 'true', 'yes', '0E0' 
# or the number 1.
#
sub is_truthy {
    my ($parm) = validate_params(\@_, [1]);

    my @truth = qw(yes true t 1 0e0);

    return scalar(grep {lc($parm) eq $_} @truth);

}

# Checks to see if the parameter is the string 'f', 'false', 'no' or 
# the number 0.
#
sub is_falsey {
    my ($parm) = validate_params(\@_, [1]);

    my @truth = qw(no false f 0);

    return scalar(grep {lc($parm) eq $_} @truth);

}

sub bool {
    my ($item) = validate_params(\@_, [1]);

    my @truth = qw(yes true 1 0e0 no false f 0);
    return grep {lc($item) eq $_} @truth;

}

sub spawn {
    my $p = validate_params(\@_, {
        -command => 1,
        -timeout => { optional => 1, default => 0 },
    });

    local $SIG{ALRM} = sub {
        my $sig_name = shift;
        die "$sig_name";
    };

    my $kid;
    my @output;

    defined( my $pid = open($kid, "-|" ) ) or do {

        my $ex = XAS::Exception->new(
            info => "unable to fork, reason: $!",
            type => 'xas.utils.spawn'
        );

        $ex->throw;

    };

    if ($pid) {

        # parent

        try {

            alarm( $p->{'timeout'} );

            while (<$kid>) {

                chomp;
                push(@output, $_);

            }

            alarm(0);

        } catch {

            my $ex = $_;

            alarm(0);

            if ($ex =~ /alrm/i) {

                unless (kill_proc(-signal => 'TERM', -pid => $pid)) {

                    unless (kill_proc(-signal => 'KILL', -pid => $pid)) {

                        my $ex = XAS::Exception->new(
                            type => 'xas.utils.spawn',
                            info => 'unable to kill ' . $pid
                        );

                        $ex->throw;

                    }

                }

            } else {

                die $ex;

            }

        };

    } else {

        # child

        # set the child process to be a group leader, so that
        # kill -9 will kill it and all its descendents

        setpgrp(0, 0);
        exec $p->{'command'};
        exit;

    }

    wantarray ? @output : join( "\n", @output );

}

sub kill_proc {
    my $p = validate_params(\@_, {
        -signal => 1,
        -pid    => 1,
    });

    my $time = 10;
    my $status = 0;
    my $pid = $p->{'pid'};
    my $signal = $p->{'signal'};

    kill($signal, $pid);

    do {

        sleep 1;
        $status = waitpid($pid, WNOHANG);
        $time--;

    } while ($time && not $status);

    return $status;

}

sub exitcode {

    my $rc  = $? >> 8;      # return code of command
    my $sig = $? & 127;     # signal it was killed with

    return $rc, $sig;

}

sub _do_fork {

    my $child = fork();

    unless (defined($child)) {

        my $ex = XAS::Exception->new(
            type => 'xas.utils.daemonize',
            info => "unable to fork, reason: $!"
        );

        $ex->throw;

    }

    exit(0) if ($child);

}

sub daemonize {

    _do_fork(); # initial fork
    setsid();   # become session leader
    _do_fork(); # second fork to prevent aquiring a controlling terminal

    # change directory to a netural place and set the umask

    chdir('/');
    umask(0);

    # redirect our standard file handles

    open(STDIN,  '<', '/dev/null');
    open(STDOUT, '>', '/dev/null');
    open(STDERR, '>', '/dev/null');

}

sub db2dt {
    my ($p) = validate_params(\@_, [
        { regex => qr/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/ }
    ]);

    my $parser = DateTime::Format::Strptime->new(
        pattern => '%Y-%m-%d %H:%M:%S',
        time_zone => 'local',
        on_error => sub {
            my ($obj, $err) = @_;
            my $ex = XAS::Exception->new(
                type => 'xas.utils.db2dt',
                info => $err
            );
            $ex->throw;
        }
    );

    return $parser->parse_datetime($p);

}

sub dt2db {
    my ($dt) = validate_params(\@_, [
        { isa => 'DateTime' }
    ]);

    return $dt->strftime('%Y-%m-%d %H:%M:%S');

}

sub run_cmd {
    my ($command) = validate_params(\@_, [1]);

    my @output = `$command 2>&1`;
    my ($rc, $sig) = exitcode();

    return \@output, $rc, $sig;

}

sub init_module {
    my ($module, $params) = validate_params(@_, [ 
        1, 
        { optional => 1, type => HASHREF, default => {} }
    ]);

    my $obj;
    my @parts;
    my $filename;

    @parts = split("::", $module);
    $filename = File(@parts);

    try {

        require $filename . '.pm';
        $module->import();
        $obj = $module->new($params);

    } catch {

        my $x = $_;
        my $ex = XAS::Exception->new(
            type => 'xas.utils.init_module',
            info => $x
        );

        $ex->throw;

    };

    return $obj;

}

sub load_module {
    my ($module) = validate_params(\@_, [1]);

    my @parts;
    my $filename;

    @parts = split("::", $module);
    $filename = File(@parts);

    try {

        require $filename . '.pm';
        $module->import();

    } catch {

        my $x = $_;
        my $ex = XAS::Exception->new(
            type => 'xas.utils.load_module',
            info => $x
        );

        $ex->throw;

    };

}

sub glob2regex {
    my ($globstr) = validate_params(\@_, [1]);

    my %patmap = (
        '*' => '.*',
        '?' => '.',
        '[' => '[',
        ']' => ']',
    );

    $globstr =~ s{(.)} { $patmap{$1} || "\Q$1" }ge;

    return '^' . $globstr . '$';

}

sub env_store {

    my %env;

    while (my ($key, $value) = each(%ENV)) {

        $env{$key} = $value;

    }

    return \%env;

}

sub env_clear {
    
    while (my ($key, $value) = each(%ENV)) {
        
        delete $ENV{$key};
        
    }
    
}

sub env_restore {
    my ($env) = validate_params(\@_, [1]);

    while (my ($key, $value) = each(%ENV)) {

        delete $ENV{$key};

    }

    while (my ($key, $value) = each(%{$env})) {

        $ENV{$key} = $value;

    }

}

sub env_create {
    my ($env) = validate_params(\@_, [1]);

    while (my ($key, $value) = each(%{$env})) {

        $ENV{$key} = $value;

    }

}

sub env_parse {
    my ($env) = validate_params(\@_, [1]);

    my ($key, $value, %env);
    my @envs = split(';;', $env);

    foreach my $y (@envs) {

        ($key, $value) = split('=', $y);
        $env{$key} = $value;

    }

    return \%env;

}

sub env_dump {

    my $env;

    while (my ($key, $value) = each(%ENV)) {

        $env .= "$key=$value;;";

    }

    # remove the ;; at the end

    chop $env;
    chop $env;

    return $env;

}

1;

__END__

=head1 NAME

XAS::Utils - A Perl extension for the XAS environment

=head1 SYNOPSIS

 use XAS::Class
   version => '0.01',
   base    => 'XAS::Base',
   utils   => 'db2dt dt2db'
 ;

 printf("%s\n", dt2db($dt));

=head1 DESCRIPTION

This module provides utility routines that can by loaded into your current 
namespace. 

=head1 METHODS

=head2 db2dt($datestring)

This routine will take a date format of YYYY-MM-DD HH:MM:SS and convert it
into a DateTime object.

=head2 dt2db($datetime)

This routine will take a DateTime object and convert it into the following
string: YYYY-MM-DD HH:MM:SS

=head2 trim($string)

Trim the whitespace from the beginning and end of $string.

=head2 ltrim($string)

Trim the whitespace from the end of $string.

=head2 rtrim($string)

Trim the whitespace from the beginning of $string.

=head2 compress($string)

Reduces multiple whitespace to a single space in $string.

=head2 left($string, $offset)

Return the left chunk of $string up to $offset. Useful for porting
VBS code. Makes allowances that VBS strings are ones based while 
Perls are zero based.

=head2 right($string, $offset)

Return the right chunk of $string starting at $offset. Useful for porting 
VBS code. Makes allowances that VBS strings are ones based while Perls 
are zero based.

=head2 mid($string, $offset, $length)

Return the chunk of $string starting at $offset for $length characters.
Useful for porting VBS code. Makes allowances that VBS strings are ones
based while Perls are zero based.

=head2 instr($start, $string, $compare)

Return the position in $string of $compare. You may offset within the
string with $start. Useful for porting VBS code. Makes allowances that
VBS strings are one based while Perls are zero based.

=head2 spawn

Run a cli command with timeout. Returns output from that command.

=over 4

=item B<-command>

The command string to run.

=item B<-timeout>

An optional timeout in seconds. Default is none.

=back

=head2 exitcode

Decodes Perls version of the exit code from a cli process. Returns two items.

 Example:

     my @output = spawn(-command => "ls -l");
     my ($rc, $sig) = exitcode();

=head2 run_cmd($command)

Run a command and capture the output and exit code, stderr is merged
with stdout.

 Example:
 
     my (@output, $rc) = run_cmd("ls -l");

=head2 daemonize

Become a daemon. This will set the process as a session lead, change to '/',
clear the protection mask and redirect stdin, stdout and stderr to /dev/null.

=head2 glob2regx($glob)

This method will take a shell glob pattern and convert it into a Perl regex.
This also works with DOS/Windows wildcards.

=over 4

=item B<$glob>

The wildcard to convert.

=back

=head2 hash_walk

This routine will walk a HOH and does a callback on the key/values that are 
found. It takes these parameters:

=over 4

=item B<-hash>

The hashref of the HOH.

=item B<-keys>

An arrayref of the key levels.

=item B<-callback>

The routine to call with these parameters:

=over 4

=item B<$key>

The current hash key.

=item B<$value>

The value of that key.

=item B<$key_list>

A list of the key depth.

=back

=back

=head2 dir_walk

This will walk a directory structure and execute a callback for the found 
files. It takes these parameters:

=over 4

=item B<-directory>

The root directory to start from.

=item B<-filter>

A compiled regex to compare files against.

=item B<-callback>

The callback to execute when matching files are found.

=back

=head2 init_module($module, $options)

This routine will load and initialize a module. It takes one required parameter
and one optinal parameter.

=over 4

=item B<$module>

The name of the module.

=item B<$options>

A hashref of optional options to use with the module.

=back

=head2 load_module($module)

This routine will load a module. 

=over 4

=item B<$module>

The name of the module.

=back

=head2 env_store

Remove all items from the $ENV variable and store them in a hash variable.

  Example:
    my $env = env_store();

=head2 env_restore

Remove all items from $ENV variable and restore it back to a saved hash variable.

  Example:
    env_restore($env);

=head2 env_create

Store all the items from a hash variable into the $ENV varable.

  Example:
    env_create($env);

=head2 env_parse

Take a formated string and parse it into a hash variable. The string must have
this format: "item=value;;item2=value2";

  Example:
    my $string = "item=value;;item2=value2";
    my $env = env_parse($string);
    env_create($env);

=head2 env_dump

Take the items from the current $ENV variable and create a formated string.

  Example:
    my $string = env_dump();
    my $env = env_create($string);

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=item L<Badger::Utils|https://metacpan.org/pod/Badger::Utils>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
