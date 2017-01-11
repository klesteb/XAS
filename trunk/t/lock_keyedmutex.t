#!/usr/bin/perl -w

use strict;
use warnings;

use Try::Tiny;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {

    plan( skip_all => "Author tests not required for installation" );

} else {

    try {

        no warnings;
        require KeyedMutex;
        plan tests => 7;

    } catch {

        my $ex = $_;
        plan skip_all => "KeyedMutex needs to be installed";

    };

}

# start flom in the background.

system('pkill keyedmutexd');
system('keyedmutexd -f -s 9507 -m 2048');

# start testing

use XAS::Lib::Lockmgr::Flom;
use Badger::Filesystem 'cwd Dir';

my $key = Dir(cwd, 'locked')->path;
my $locker = XAS::Lib::Lockmgr::KeyedMutex->new(
    -key => $key,
    -args => {
        port    => 9507,
        address => '127.0.0.1',
    }
);

# basic tests

ok( defined $locker );                                 # check that we got something
ok( $locker->isa('XAS::Lib::Lockmgr::KeyedMutex') );   # and it's the right class
ok( $locker->key eq $key );

ok( $locker->try_lock );
ok( $locker->lock );
ok( $locker->unlock );

system('pkill keyedmutexd');

