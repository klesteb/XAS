
use lib '../lib';
use strict;
use warnings;

use XAS::Lib::Lockmgr::Mutex;

my $lock = XAS::Lib::Lockmgr::Mutex->new(
    -key => 'testing'
);

