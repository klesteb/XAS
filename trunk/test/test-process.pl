
use lib '../lib';

use XAS::Lib::Process;
use Badger::Filesystem 'Dir';

my $command = 'perl test.pl';

my $process = XAS::Lib::Process->new(
    -command      => $command,
    -directory    => Dir('.'),
#    -redirect     => 1,
#    -auto_restart => 0,
    -environment  => { testing => 'this is a test' },
);

$SIG{'TERM'} = sub {
    $process->kill();
};

$process->log->level('debug', 1);
$process->run();

