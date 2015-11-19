use lib '../lib';

use Data::Dumper;
use XAS::Lib::SSH::Client::Shell;

my $command = '/home/kevin/dev/XAS/trunk/test/ssh-echo-server.sh';
my $shell = XAS::Lib::SSH::Client::Shell->new(
    -host   => 'localhost',
    -username => 'kevin',
    -priv_key => '/home/kevin/.ssh/id_rsa',
    -pub_key  => '/home/kevin/.ssh/id_rsa.pub',
);

$shell->connect();

$shell->run($command);

$shell->call("this is a test", sub {
    my $output = shift;
    foreach my $line (@$output) {
        printf("%s\n", $line);
    }
});

$shell->call("this is another test", sub {
    my $output = shift;
    foreach my $line (@$output) {
        printf("%s\n", $line);
    }
});

$shell->call("this is another test again", sub {
    my $output = shift;
    foreach my $line (@$output) {
        printf("%s\n", $line);
    }
});

$shell->disconnect();

