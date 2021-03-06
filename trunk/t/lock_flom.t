#!/usr/bin/perl -w

use strict;
use warnings;

use Try::Tiny;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {

    plan skip_all => 'Author tests not required for installation';

} else {

    try {

        no warnings;
        require Flom;

        plan tests => 6;

    } catch {

        my $ex = $_;
        plan skip_all => 'FLoM (the Free Lock Manager) needs to be installed';

    };

}

# start flom in the background.

system('pkill flom');
system('flom -a 127.0.0.1 -d -1 -- true');

# start testing

use XAS::Lib::Lockmgr::Flom;
use Badger::Filesystem 'cwd Dir';

my $key = Dir(cwd, 'locked')->path;
my $locker = XAS::Lib::Lockmgr::Flom->new(
    -key => $key,
    -args => {
        address => '127.0.0.1',
    }
);

# basic tests

ok( defined $locker );                                 # check that we got something
ok( $locker->isa('XAS::Lib::Lockmgr::Flom') );         # and it's the right class
ok( $locker->key eq $key );

ok( $locker->try_lock );
ok( $locker->lock );
ok( $locker->unlock );

system('pkill flom');

