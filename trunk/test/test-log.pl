use lib '../lib';
use Data::Dumper;
use XAS::Factory;

my $log = XAS::Factory->module('log');

$log->info('it works');
$log->level('debug', 1);
printf("debug = %s\n", $log->level('debug'));
$log->debug('debug works');
$log->trace('trace works');
$log->info("this is", "a test");
$log->info_msg('exception', 'first', 'second');
$log->info_msg('caller', 'one', 'two', 'three', 'four');

#my $messages = $log->class->var('MESSAGES');
#warn Dumper($messages);

