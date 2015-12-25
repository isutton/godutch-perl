#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Panamax' ) || print "Bail out!\n";
}

diag( "Testing Panamax $Panamax::VERSION, Perl $], $^X" );
