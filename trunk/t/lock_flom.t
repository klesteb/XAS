#!/usr/bin/perl -w

# assume these two lines are in all subsequent examples
use strict;
use warnings;

use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {

    plan( skip_all => "Author tests not required for installation" );

} else {

    plan tests => 6;

}


use XAS::Lib::Lockmgr::Flom;
use Badger::Filesystem 'cwd Dir';

my $key = Dir(cwd, 'locked')->path;
my $locker = XAS::Lib::Lockmgr::Flom->new(
    -key => $key
);

# basic tests

ok( defined $locker );                                 # check that we got something
ok( $locker->isa('XAS::Lib::Lockmgr::Flom') );         # and it's the right class
ok( $locker->key eq $key );

ok( $locker->try_lock );
ok( $locker->lock );
ok( $locker->unlock );


