package Panamax;

use 5.006;
use strict;
use warnings;

use Panamax::JSON ();
use IO::Socket::UNIX;
use File::Spec;



our $CHECK_DOES_NOT_EXIST_ERROR = "Check does not exist";



sub new {
    my ( $class, %opts ) = @_;

    my $socket_path      = $opts{socket_path};
    my $available_checks = $opts{available_checks};

    my $self = {
        socket_path      => $socket_path,
        available_checks => $available_checks,
    };
    return bless $self, $class;
}



sub _log {
    my ( $self, $severity, @rest ) = @_;

    printf "[%s] " . shift(@rest) . $/, $severity, @rest;
}


    
sub debug {
    return shift->_log( "DEBUG", @_ );
}



sub info {
    return shift->_log( "INFO", @_ );
}



sub perform {
    my ( $self, $request ) = @_;

    # We return the payload without 'status' if we can't find this
    # check in our available checks.
    if ( !exists $self->{available_checks}{ $request->{command} } ) {
        return { 
            name  => $request->{command}, 
            error => $CHECK_DOES_NOT_EXIST_ERROR,
        };
    }

    my $command = $self->{available_checks}{ $request->{command} };
    return $command->( $request->{arguments} );
}



sub start {
    my ( $self ) = @_;

    my $server = IO::Socket::UNIX->new(
        Type   => SOCK_STREAM(),
        Local  => $self->{socket_path},
        Listen => 1,
    ) or die $!;

    $SIG{INT} = sub {
        $self->info( "SIGINT: closing socket and leaving" );
        $server->close;
        unlink $self->{socket_path};
        exit(0);
    };

    $self->info( "Listening on %s", $self->{socket_path} );

    while ( my $conn = $server->accept() ) {

        chomp( my $request_json = <$conn> );

        $self->debug( $request_json );

        my $request = Panamax::JSON::from_json( $request_json );

        my $response = $self->perform( $request );

        my $response_json = Panamax::JSON::to_json( $response );

        $self->debug( $response_json );

        print $conn $response_json;

        $conn->flush;
    }

}


1; # End of Panamax
