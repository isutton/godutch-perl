#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw( $Bin );
use lib "$Bin/../lib";

use Config;
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

my $perl_path    = $Config{perlpath};
my $socket_path  = $ENV{HOME} . "/godutch.basic.socket";
my $include_path = "$Bin/lib";
my $godutch_path = "$Bin/../bin/godutch";


sub server_setup_1 {
    my @cmd = (
        $perl_path,
        $godutch_path,
        '-I', $include_path,
        '--module',   'Basic',
        '--function', 'checks',
        '--socket',   $socket_path,
    );

    my ( $in, $out, $err );
    my $h = start \@cmd, \$in, \$out, \$err;


    return ( $h );
}

sub server_setup_2 {
    $ENV{GODUTCH_FUNCTION}    = 'checks';
    $ENV{GODUTCH_INC}         = $include_path;
    $ENV{GODUTCH_MODULE}      = 'Basic';
    $ENV{GODUTCH_SOCKET_PATH} = $socket_path;

    my @cmd  = (
        $perl_path,
        $godutch_path,
    );

    my ( $in, $out, $err );
    my $h = start \@cmd, \$in, \$out, \$err;

    return ( $h );
}

sub server_setup_3 {
    my @cmd         = (
        $perl_path,
        $godutch_path,
        '-I',          $include_path,
        '--module',   'Basic',
        '--function', 'checks',
    );
    $ENV{GODUTCH_SOCKET_PATH} = $socket_path;

    my ( $in, $out, $err );
    my $h = start \@cmd, \$in, \$out, \$err;

    return ( $h );
}

for my $setup_function ( \&server_setup_1, \&server_setup_2, \&server_setup_3 ) {

    my ( $h ) = $setup_function->();

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
                name   => 'check02',
                status => GoDutch::UNKNOWN(),
                error  => $GoDutch::CHECK_DOES_NOT_EXIST_ERROR,
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
