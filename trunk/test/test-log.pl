use lib '../lib';
use XAS::Factory;

our $MESSAGES = {
    testing => 'this is a test'
};

my $log = XAS::Factory->module('log');

$log->info('it works');
$log->level('debug', 1);
printf("debug = %s\n", $log->level('debug'));
$log->debug('debug works');
$log->trace('trace works');
$log->info("this is", "a test");
$log->info_msg('exception', 'first', 'second');

