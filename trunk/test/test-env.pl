
use lib '../lib';
use Data::Dumper;
use XAS::Factory;
use XAS::Lib::Modules::Environment;
use Badger::Filesystem 'Dir File';

#my $env = XAS::Factory->module('environment');
my $env = XAS::Lib::Modules::Environment->new();

$env->pidfile(File('test.pid'));

warn sprintf("pidfile = %s\n", $env->pidfile);
warn sprintf("spool = %s\n", $env->spool);

$env->spool(File('/opt/xas/spool'));
    
my $env1 = XAS::Factory->module('environment');

warn sprintf("pidfile = %s\n", $env1->pidfile);
warn sprintf("spool = %s\n", $env1->spool);

