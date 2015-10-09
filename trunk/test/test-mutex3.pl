
use lib '../lib';
use strict;
use warnings;

use XAS::Lib::Lockmgr::Mutex;

my $locker = XAS::Lib::Lockmgr::Mutex->new(
    -args => {
        key => 'testing',
        mode => 0600,
    }
);

$locker->log->level('debug',1 );
$locker->log->info('attempting lock');

#if ($locker->try_lock()) {

    $locker->log->info('before lock');
    $locker->lock();
    $locker->log->info('aquired lock');
    sleep 60;
    $locker->unlock();
    $locker->log->info('released lock');

#}

