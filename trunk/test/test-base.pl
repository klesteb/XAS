use lib '../lib';

package Test;

use XAS::Class
  version => '0.01',
  base    => 'XAS::Base'
;

package main;

my $test = Test->new(-xdebug => 1, -alerts => 1);

printf("xdebug = %s\n", $test->xdebug);
printf("alerts = %s\n", $test->alerts);

