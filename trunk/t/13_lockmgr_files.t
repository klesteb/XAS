use strict;
use Test::More;
#use Data::Dumper;
use lib "../lib";

BEGIN {

    unless ($ENV{RELEASE_TESTING}) {

        plan( skip_all => "Author tests not required for installation" );

    } else {

       plan(tests => 17);
       use_ok("XAS::Lib::Lockmgr");

    }

}

my $lockmgr = XAS::Lib::Lockmgr->new(
    -driver => 'Files',
    -args => {
        directory => '.'
    }
);

# basic does it work..

isa_ok($lockmgr, 'XAS::Lib::Lockmgr');
ok($lockmgr->allocate('testing'));
ok($lockmgr->lock('testing'));
ok($lockmgr->unlock('testing'));
ok($lockmgr->deallocate('testing'));

