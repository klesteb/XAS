
use lib '../lib';

package Test;

use XAS::Class
  version => '0.01',
  base    => 'XAS::Base',
;

package main;

my $test = Test->new();

$test->env->mxmailer('smtp');
$test->email->send(
    -to => 'kevin',
    -from => 'testing',
    -subject => 'this is a test'
);

1;

