#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw( $Bin );
use lib "$Bin/../lib";

use Data::Dumper;
use IO::Socket::UNIX;
use IPC::Run qw( start signal );
use Test::More qw( no_plan );
use JSON;

use Panamax;
use Panamax::Client;

$| = 1;

my $panamax_bin = "$Bin/../bin/panamax";
my $socket_path = "/tmp/panamax.basic.socket";
my @cmd         = ( 
    $panamax_bin, 
    '-I', "$Bin/lib",
    '--module',   'Basic',
    '--function', 'checks',
    '--socket',   $socket_path,
);

my ( $in, $out, $err );
my $h = start \@cmd, \$in, \$out, \$err;

sleep 1;

eval {
    my $client   = Panamax::Client->new( socket_path => $socket_path );
    my $response = $client->perform( "check01", [] );

    is_deeply( 
        $response,
        { 
            name => 'check01',
            status => 0,
            stdout => [],
        },
        "Successful dummy check"
    );

    $response = $client->perform( "check02", [] );

    is_deeply(
        $response,
        {
            name  => 'check02',
            error => $Panamax::CHECK_DOES_NOT_EXIST_ERROR,
        },
        "Not existing check should return an error"
    );

    1;
} or do {
    fail("Client couldn't open connection to $socket_path");
};

signal $h, 'INT';

unlink $socket_path 
    if -e $socket_path;
