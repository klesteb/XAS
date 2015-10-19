
use lib '../lib';

package Test;

use XAS::Class
  version => '0.01',
  base    => 'XAS::Base',
;

package main;

my $test = Test->new();

printf("logfile = %s\n", $test->env->logfile);
printf("alerts = %s\n",  $test->env->alerts);
printf("xdebug = %s\n",  $test->env->xdebug);
printf("level = %s\n",   $test->log->level('debug'));

1;


