#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {

    plan( skip_all => "Author tests not required for installation" );

} else {

    plan tests => 57;

}

use Data::Dumper;
use XAS::Lib::Lockmgr;
use Badger::Filesystem 'cwd Dir File';

my $locker = XAS::Lib::Lockmgr->new(
    -breaklock  => 1,
    -deadlocked => 1,    # minutes
    -timeout    => 30,   # seconds
    -attempts   => 5,
);

my $lock;
my ($host, $pid, $time);
my $key = Dir(cwd, 'locked')->path;
my $chost = $locker->env->host;
my $p = ($^O eq 'MSWin32') ? 0 : 1; # windows null process vs unix init

#
# basic tests
#

ok( defined $locker );                     # check that we got something
ok( $locker->isa('XAS::Lib::Lockmgr') );   # and it's the right class

#
# loading and unloading lock module
#

ok( $locker->add(-key => $key) );
ok( defined($locker->lockers->{$key}) );
ok( $locker->remove($key) );
ok( ! defined($locker->lockers->{$key}) );
ok( $locker->add(-key => $key) );

#
# basic locking
#

ok( $locker->lock($key) );

# who owns the lock

($host, $pid, $time) = $locker->lockers->{$key}->whose_lock();
ok( $host eq $locker->env->host );
ok( $pid == $$);
ok( $time->isa('DateTime') );

ok( $locker->unlock($key) );
ok( ! -d $key);

#
# orphaned lock directory
#

mkdir $key;

# who owns the lock

ok( ($host, $pid, $time) = $locker->lockers->{$key}->whose_lock );
ok( ! defined($host) );
ok( ! defined($pid) );
ok( ! defined($time) );

ok( $locker->lock($key) );
ok( $locker->unlock($key) );
ok( ! -d $key);

#
# remote lock, local process should aquire the lock
#

mkdir $key;

$lock = File($key, 'remote.1234');
$lock->create;
ok( $lock->exists );

# who owns the lock

ok( ($host, $pid, $time) = $locker->lockers->{$key}->whose_lock );
ok( $host eq 'remote' );
ok( $pid == 1234 );
ok( $time->isa('DateTime') );

ok( $locker->lock($key) );

# check paths

ok( ! $lock->exists );
ok( -d $key );

# who owns the lock

ok( ($host, $pid, $time) = $locker->lockers->{$key}->whose_lock );
ok( $host eq $locker->env->host );
ok( $pid == $$ );
ok( $time->isa('DateTime') );

ok( $locker->unlock($key) );
ok( ! -d $lock->path);

#
# competing process, using try_lock to detect availablity
#

# create a lock

mkdir $key;

$lock = File($key, "$chost.$p");
$lock->create;
ok( $lock->exists );

# who owns the lock

ok( ($host, $pid, $time) = $locker->lockers->{$key}->whose_lock );
ok( $host eq $chost );
ok( $pid == $p );
ok( $time->isa('DateTime') );

ok( ! $locker->lock($key) );
ok( $lock->exists );

# break the lock

do {

    sleep 10;

} until ($locker->try_lock($key));

ok( ! -d $lock->path);

# aquire the lock

ok( $locker->lock($key) );
ok( $locker->unlock($key) );
ok( ! -d $key);

#
# competing process, once again, but with lock()
#

# create the lock

mkdir $key;
$lock = File($key, "$chost.$p");
$lock->create;
ok( $lock->exists );

# who owns the lock

ok( ($host, $pid, $time) = $locker->lockers->{$key}->whose_lock );
ok( $host eq $chost );
ok( $pid == $p );
ok( $time->isa('DateTime') );

# aquire the lock

do {

    sleep 10;

} until ($locker->lock($key));

# check paths

ok( ! -d $lock->path);
ok( -d $key);

# who owns the lock

($host, $pid, $time) = $locker->lockers->{$key}->whose_lock();
ok( $host eq $locker->env->host );
ok( $pid == $$);
ok( $time->isa('DateTime') );

# remove our lock

ok( $locker->unlock($key) );
ok( ! -d $key);

