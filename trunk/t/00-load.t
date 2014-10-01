#!perl

use Test::More tests => 46;

BEGIN {
    use_ok( 'XAS::Base' )                        || print "Bail out!\n";
    use_ok( 'XAS::Class' )                       || print "Bail out!\n";
    use_ok( 'XAS::Constants' )                   || print "Bail out!\n";
    use_ok( 'XAS::Exception' )                   || print "Bail out!\n";
    use_ok( 'XAS::Factory' )                     || print "Bail out!\n";
    use_ok( 'XAS::Singleton' )                   || print "Bail out!\n";
    use_ok( 'XAS::Utils' )                       || print "Bail out!\n";
    use_ok( 'XAS::Apps::Test::Service' )         || print "Bail out!\n";
    use_ok( 'XAS::Apps::Test::Echo::Client' )    || print "Bail out!\n";
    use_ok( 'XAS::Apps::Test::Echo::Server' )    || print "Bail out!\n";
    use_ok( 'XAS::Apps::Logger' )                || print "Bail out!\n";
    use_ok( 'XAS::Apps::Rotate' )                || print "Bail out!\n";
    use_ok( 'XAS::Lib::App::Daemon' )            || print "Bail out!\n";
    use_ok( 'XAS::Lib::App::Services' )          || print "Bail out!\n";
    use_ok( 'XAS::Lib::Curses::Root' )           || print "Bail out!\n";
    use_ok( 'XAS::Lib::Curses::Toolkit' )        || print "Bail out!\n";
    use_ok( 'XAS::Lib::Mixins::Configs' )        || print "Bail out!\n";
    use_ok( 'XAS::Lib::Mixins::Handlers' )       || print "Bail out!\n";
    use_ok( 'XAS::Lib::Mixins::Iterator' )       || print "Bail out!\n";
    use_ok( 'XAS::Lib::Mixins::Keepalive' )      || print "Bail out!\n";
    use_ok( 'XAS::Lib::Modules::Alerts' )        || print "Bail out!\n";
    use_ok( 'XAS::Lib::Modules::Email' )         || print "Bail out!\n";
    use_ok( 'XAS::Lib::Modules::Environment' )   || print "Bail out!\n";
    use_ok( 'XAS::Lib::Modules::Locking' )       || print "Bail out!\n";
    use_ok( 'XAS::Lib::Modules::Log' )           || print "Bail out!\n";
    use_ok( 'XAS::Lib::Modules::Log::File' )     || print "Bail out!\n";
    use_ok( 'XAS::Lib::Modules::Log::Logstash' ) || print "Bail out!\n";
    use_ok( 'XAS::Lib::Modules::Log::Syslog' )   || print "Bail out!\n";
    use_ok( 'XAS::Lib::Modules::Spool' )         || print "Bail out!\n";
    use_ok( 'XAS::Lib::Net::Client' )            || print "Bail out!\n";
    use_ok( 'XAS::Lib::Net::POE::Client' )       || print "Bail out!\n";
    use_ok( 'XAS::Lib::Net::Server' )            || print "Bail out!\n";
    use_ok( 'XAS::Lib::POE::PubSub' )            || print "Bail out!\n";
    use_ok( 'XAS::Lib::POE::Service' )           || print "Bail out!\n";
    use_ok( 'XAS::Lib::POE::Session' )           || print "Bail out!\n";
    use_ok( 'XAS::Lib::SSH::Client' )            || print "Bail out!\n";
    use_ok( 'XAS::Lib::SSH::Client::Exec' )      || print "Bail out!\n";
    use_ok( 'XAS::Lib::SSH::Client::Shell' )     || print "Bail out!\n";
    use_ok( 'XAS::Lib::SSH::Client::Subsystem' ) || print "Bail out!\n";
    use_ok( 'XAS::Lib::SSH::Server' )            || print "Bail out!\n";
    use_ok( 'XAS::Lib::Stomp::Frame' )           || print "Bail out!\n";
    use_ok( 'XAS::Lib::Stomp::Parser' )          || print "Bail out!\n";
    use_ok( 'XAS::Lib::Stomp::POE::Client' )     || print "Bail out!\n";
    use_ok( 'XAS::Lib::Stomp::POE::Filter' )     || print "Bail out!\n";
    use_ok( 'XAS::Lib::Stomp::Utils' )           || print "Bail out!\n";
    use_ok( 'XAS' )                              || print "Bail out!\n";
}

diag( "Testing XAS $XAS::VERSION, Perl $], $^X" );
