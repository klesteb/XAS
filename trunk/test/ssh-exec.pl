use lib '../lib';

use XAS::Lib::SSH::Client::Exec;

my $shell = XAS::Lib::SSH::Client::Exec->new(
    -host     => 'localhost',
    -username => 'kevin',
    -priv_key => '/home/kevin/.ssh/id_rsa',
    -pub_key  => '/home/kevin/.ssh/id_rsa.pub',
);

$shell->connect();

$shell->call("ls -la", sub {
    my $output = shift;

    foreach my $line (@$output) {

        printf("%s\n", $line);

    }

});

$shell->disconnect();

