use lib '../lib';
use strict;
use warnings;

use XAS::Lib::Lockmgr;

my $key = 'testing';
my $lockmgr = XAS::Lib::Lockmgr->new();

$lockmgr->log->level('debug', 1);
$lockmgr->add(-key => $key);

if ($lockmgr->try_lock($key)) {

    $lockmgr->lock($key);
    sleep 10;
    $lockmgr->unlock($key);

}

