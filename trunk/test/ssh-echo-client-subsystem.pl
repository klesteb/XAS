use lib '../lib';

use Data::Dumper;
use XAS::Lib::SSH::Client::Subsystem;

my $shell = XAS::Lib::SSH::Client::Subsystem->new(
    -server   => 'localhost',
    -username => 'kevin',
    -priv_key => '/home/kevin/.ssh/id_rsa',
    -pub_key  => '/home/kevin/.ssh/id_rsa.pub',
);

my $first = 1;
my $output;

$SIG{'TERM'} = sub {
    $shell->disconnect();
};

$shell->connect();

$shell->run('testing');

# sync with the server

$shell->puts('noop');

do {

    $output = $shell->gets();

} until ($output eq 'noop');

# synced

$shell->call("this is a test", sub {
    my $output = shift;
    printf("%s\n", $output);
});

$shell->call("this is another test", sub {
    my $output = shift;
    printf("%s\n", $output);
});

$shell->call("this is another test again", sub {
    my $output = shift;
    printf("%s\n", $output);
});

$shell->disconnect();

