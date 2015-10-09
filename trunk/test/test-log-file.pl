use lib '../lib';
use XAS::Factory;
use Badger::Filesystem 'File';

my $log = XAS::Factory->module('log');

$log->info('it works');
$log->level('debug', 1);
printf("debug = %s\n", $log->level('debug'));

$log->warn('switching to file');
$log->env->logtype('file');
$log->env->logfile(File('test.log'));
$log->activate();
  
$log->debug('debug works');
$log->trace('trace works');
$log->info("this is", "a test");
$log->info_msg('exception', 'this is', 'a test');

