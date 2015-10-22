
use lib '../lib';
use strict;
use warnings;

use XAS::Lib::Lockmgr::Mutex;

my $locker = XAS::Lib::Lockmgr::Mutex->new(
    -key => 'testing',
    -args => {
        key => 'testing',
        mode => 0660,
    }
);

$locker->log->level('debug',1 );

printf("attempting lock\n");

if ($locker->try_lock()) {

    printf("before lock\n");
    $locker->lock();
    printf("aquired lock\n");
    $locker->unlock();
    printf("released lock\n");

}

