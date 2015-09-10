use strict;
use lib '../lib';

use Test::More;
use Badger::Filesystem 'Dir';
use Data::Dumper;

unless ( $ENV{RELEASE_TESTING} ) {

    plan( skip_all => "Author tests not required for installation" );

} else {

    plan(tests => 21);
    use_ok("XAS::Lib::Modules::Spool");

    unless ( -e 'spool') {
        mkdir('spool');
    }

}

my $data = 'this is data';
my $spl = XAS::Lib::Modules::Spool->new(
    -directory => Dir('spool'),
);
isa_ok($spl, "XAS::Lib::Modules::Spool");

ok($spl->write($data));
ok($spl->write($data));
ok($spl->write($data));
ok($spl->write($data));

my $packet;
my @files = $spl->scan();
my $count = $spl->count();
is(scalar(@files), $count);

foreach my $file (@files) {

    ok($packet = $spl->read($file));
    is($packet, $data);
    ok($spl->delete($file));

}

ok(unlink('spool/.SEQ'));
ok(rmdir('spool'));

