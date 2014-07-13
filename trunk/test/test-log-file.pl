use lib '../lib';
use XAS::Factory;

my $log = XAS::Factory->module('log', { 
   -type     => 'file',
   -filename => 'test.log',
   -levels => {
       trace => 1
   }
});

$log->info('it works');
$log->level('debug', 1);
printf("debug = %s\n", $log->level('debug'));
$log->debug('debug works');
$log->trace('trace works');
$log->info("this is", "a test");
$log->info_msg('exception', 'this is', 'a test');

    
