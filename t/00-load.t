#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'GoDutch' ) || print "Bail out!\n";
}

diag( "Testing GoDutch $GoDutch::VERSION, Perl $], $^X" );
