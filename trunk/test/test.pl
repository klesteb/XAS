#!/usr/bin/perl

use strict;
use warnings;

$| = 1;

while (my ($key, $value) = each(%ENV)) {

    printf("%s = %s\n", $key, $value);

}

for (1..5) {

    print "testing\n";

}

sleep 60;

exit 1;
