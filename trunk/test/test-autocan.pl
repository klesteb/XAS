
use lib '../lib';

package Test;

use XAS::Class
  version => '0.01',
  base    => 'XAS::Base',
;

package main;

my $test = Test->new(-xdebug => 1);

my $logfile = $test->env->logfile;

printf("logfile = %s\n", $logfile);

1;

