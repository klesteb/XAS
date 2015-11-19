use lib '../lib';
use XAS::Factory;

my $log = XAS::Factory->module('log');

$log->env->log_type('syslog');
$log->activate();

$log->info('it works');
$log->level('debug', 1);
printf("debug = %s\n", $log->level('debug'));
$log->debug('debug works');
$log->trace('trace works');
$log->info("this is", "a test");

