package GoDutch::Client;

use strict;
use warnings;

use IO::Socket::UNIX;
use GoDutch::JSON;

sub new {
    my ( $class, %opts ) = @_;

    my $self = {
        socket_path => $opts{socket_path},
    };

    return bless $self, $class;
}

sub run {
    my ( $self, $command, $arguments ) = @_;

    my $client = IO::Socket::UNIX->new(
        Type => SOCK_STREAM(),
        Peer => $self->{socket_path},
    ) or die $!;

    my $request = { 
        command   => $command, 
        arguments => $arguments,
    };

    my $request_json = GoDutch::JSON::to_json( $request );

    print $client $request_json;

    $client->flush;

    my $response_json = <$client>;

    my $response = GoDutch::JSON::from_json( $response_json );

    return $response;
}

1;
