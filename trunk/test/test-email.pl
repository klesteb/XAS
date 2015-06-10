
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
    -to      => sprintf("kevin\@%s", $test->env->domain),
    -from    => sprintf("debbie\@%s", $test->env->domain),
    -subject => 'this is a test'
);

1;

