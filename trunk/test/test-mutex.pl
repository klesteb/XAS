use lib '../lib';
use strict;
use warnings;

use Data::Dumper;
use XAS::Lib::Lockmgr;

my $key = '/run/shm/testing';
my $lockmgr = XAS::Lib::Lockmgr->new();

$lockmgr->log->level('debug', 1);
$lockmgr->add(-key => $key, -driver => 'Filesystem');

$lockmgr->log->info("pid: $$");

if ($lockmgr->try_lock($key)) {

    $lockmgr->log->info('trying lock');

    if ($lockmgr->lock($key)) {

        $lockmgr->log->info('aquired lock waiting...');
        sleep 20;

        $lockmgr->unlock($key) && $lockmgr->log->info('released lock');

    }

}

