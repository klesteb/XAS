use lib '../lib';
use strict;
use warnings;

use Data::Dumper;
use XAS::Lib::Iterator;

my @data = ['test1','test2','test3','test4'];

my $iterator = XAS::Lib::Iterator->new(@data);

printf("forward\n");

while (my $item = $iterator->next) {

    printf("index: %s, item: %s\n", $iterator->index, $item);

}

printf("backwards\n");

while (my $item = $iterator->prev) {

    printf("index: %s, item: %s\n", $iterator->index, $item);

}


printf("after positon 1\n");
$iterator->index(1);
while (my $item = $iterator->next) {

    printf("index: %s, item: %s\n", $iterator->index, $item);

}

$iterator->index(2);
printf("dumping from pos 2\n");
warn Dumper($iterator->items);

printf("stepping thru\n");

for (my $x = 1; $x <= $iterator->count; $x++) {

    if ($iterator->index($x)) {

        printf("pos: %s, index: %s, item: %s\n", $x, $iterator->index, $iterator->item);

    }

}

