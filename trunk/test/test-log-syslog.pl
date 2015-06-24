use lib '../lib';
use XAS::Factory;

my $log = XAS::Factory->module('log', { 
   -type     => 'syslog',
#   -facility => 'local7',
   -process  => $0,
   -levels => {
       debug => 1,
       trace => 1,
   }
});

$log->info('it works');
$log->level('debug', 1);
printf("debug = %s\n", $log->level('debug'));
$log->debug('debug works');
$log->trace('trace works');
$log->info("this is", "a test");

