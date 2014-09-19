#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'XAS::Base' ) || print "Bail out!\n";
    use_ok( 'XAS::Class' ) || print "Bail out!\n";
    use_ok( 'XAS::Constants' ) || print "Bail out!\n";
    use_ok( 'XAS::Exceptions' ) || print "Bail out!\n";
    use_ok( 'XAS::Factory' ) || print "Bail out!\n";
    use_ok( 'XAS::Singleton' ) || print "Bail out!\n";
    use_ok( 'XAS::Utils' ) || print "Bail out!\n";
    use_ok( 'XAS::Apps::Test::Service' ) || print "Bail out!\n";
    use_ok( 'XAS::Apps::Logger' ) || print "Bail out!\n";
    use_ok( 'XAS::Apps::Rotate' ) || print "Bail out!\n";
    use_ok( 'XAS::Lib::App::Daemon' ) || print "Bail out!\n";
    use_ok( 'XAS::Lib::App::Services) || print "Bail out!\n";
    use_ok( 'XAS::Lib::Curses::Root' ) || print "Bail out!\n";
    use_ok( 'XAS::Lib::Curses::Toolkit' ) || print "Bail out!\n";
    use_ok( 'XAS::Lib::Mixins::Configs' ) || print "Bail out!\n";
    use_ok( 'XAS::Lib::Mixins::Handlers' ) || print "Bail out!\n";
    use_ok( 'XAS::Lib::Mixins::Iterator' ) || print "Bail out!\n";
    use_ok( 'XAS::Lib::Mixins::Keepalive' ) || print "Bail out!\n";
    use_ok( 'XAS' ) || print "Bail out!\n";
    use_ok( 'XAS' ) || print "Bail out!\n";
    use_ok( 'XAS' ) || print "Bail out!\n";

}

diag( "Testing XAS $XAS::VERSION, Perl $], $^X" );
