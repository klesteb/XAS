use lib '../lib';

package Test;

use XAS::Class
  version => '0.01',
  base    => 'XAS::Base',
  vars => {
      PARAMS => {
          -test => 1,
      }
  }
;

use Data::Dumper;

sub test1 {
    my $self = shift;

    my $params = $self->validate_params(\@_, {
       -param1 => 1,
       -param2 => 1
   });

warn Dumper($params);

}

sub test2 {
    my $self = shift;

    my ($p1, $p2) = $self->validate_params(\@_, [1, 1]);

warn "$p1\n";
warn "$p2\n";

}

sub test3 {
    my $self = shift;

    my $p = $self->validate_params(\@_, [1, 1]);

warn Dumper($p);

}

package main;

my $test = Test->new(-test => 'testing');
#my $test = Test->new();

$test->test1(
    -param1 => 'testing',
    -param2 => 'another test',
);

$test->test2('testing', 'test2');

$test->test3('testing');

1;


  