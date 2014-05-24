#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'XAS' ) || print "Bail out!\n";
}

diag( "Testing XAS $XAS::VERSION, Perl $], $^X" );
