use lib '../lib';

use Data::Dumper;
use XAS::Constants 'CRLF';
use XAS::Lib::SSH::Client::Shell;

my $command = '/home/kevin/dev/XAS/trunk/test/ssh-echo-server.sh';
my $shell = XAS::Lib::SSH::Client::Shell->new(
    -host     => 'localhost',
    -username => 'kevin',
    -priv_key => '/home/kevin/.ssh/id_rsa',
    -pub_key  => '/home/kevin/.ssh/id_rsa.pub',
    -eol      => CRLF,
);

$shell->connect();

$shell->run($command);
while (my $line = $shell->gets()) {

    printf("\"%s\"\n", $line);

};

$shell->puts("this is a test");

while (my $line = $shell->gets()) {

    printf("\"%s\"\n", $line);

};

$shell->puts("this is another test");

while (my $line = $shell->gets()) {

    printf("\"%s\"\n", $line);

};

$shell->puts("this is a test again");

while (my $line = $shell->gets()) {

    printf("\"%s\"\n", $line);

};


$shell->disconnect();

