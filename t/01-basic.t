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

use GoDutch;
use GoDutch::Client;

use lib "$Bin/lib";
use Basic;

$| = 1;

sub server_setup_1 {
    my $godutch_bin = "$Bin/../bin/godutch";
    my $socket_path = "/tmp/godutch.basic.socket";
    my @cmd         = (
        $godutch_bin,
        '-I', "$Bin/lib",
        '--module',   'Basic',
        '--function', 'checks',
        '--socket',   $socket_path,
    );

    my ( $in, $out, $err );
    my $h = start \@cmd, \$in, \$out, \$err;

    return ( $h, $socket_path );
}

sub server_setup_2 {
    my $godutch_bin           = "$Bin/../bin/godutch";
    my $socket_path           = "/tmp/godutch.basic.socket";
    $ENV{GODUTCH_INC}         = "$Bin/lib";
    $ENV{GODUTCH_MODULE}      = 'Basic';
    $ENV{GODUTCH_FUNCTION}    = 'checks';
    $ENV{GODUTCH_SOCKET_PATH} = $socket_path;

    my @cmd  = (
        $godutch_bin,
    );

    my ( $in, $out, $err );
    my $h = start \@cmd, \$in, \$out, \$err;

    return ( $h, $socket_path );
}

sub server_setup_3 {
    my $godutch_bin           = "$Bin/../bin/godutch";
    my $socket_path           = "/tmp/godutch.basic.socket";
    my @cmd         = (
        $godutch_bin,
        '-I', "$Bin/lib",
        '--module',   'Basic',
        '--function', 'checks',
    );
    $ENV{GODUTCH_SOCKET_PATH} = $socket_path;

    my ( $in, $out, $err );
    my $h = start \@cmd, \$in, \$out, \$err;

    return ( $h, $socket_path );
}

for my $setup_function ( \&server_setup_1, \&server_setup_2, \&server_setup_3 ) {

    my ( $h, $socket_path ) = $setup_function->();

    sleep 1;

    eval {
        my $client   = GoDutch::Client->new( socket_path => $socket_path );
        my $response = $client->run( "check01", [] );

        is_deeply(
            $response,
            {
                name => 'check01',
                status => 0,
                stdout => [],
            },
            "Successful dummy check"
        );

        $response = $client->run( "check02", [] );

        is_deeply(
            $response,
            {
                name  => 'check02',
                error => $GoDutch::CHECK_DOES_NOT_EXIST_ERROR,
            },
            "Not existing check should return an error"
        );

        my $check_name = '__list_check_methods';
        $response = $client->run( $check_name, [] );

        is_deeply(
            $response,
            {
                name   => $check_name,
                status => 0,
                stdout => [ keys %{Basic::checks()} ],
            },
            $check_name
        );

        1;
    } or do {
        fail("Client couldn't open connection to $socket_path");
    };

    signal $h, 'INT';

    unlink $socket_path
        if -e $socket_path;

}
