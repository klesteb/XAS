
use lib '../lib';

package Test;

use XAS::Class
  version => '0.01',
  base    => 'XAS::Base',
;

package main;

my $test = Test->new();

$test->alert->send('this is a test');

1;

