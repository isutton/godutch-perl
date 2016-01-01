package GoDutch;

use 5.006;
use strict;
use warnings;

use Data::Dumper;
use AnyEvent::Socket;
use IO::Socket::UNIX;
use File::Spec;

use GoDutch::JSON ();



sub SUCCESS  { 0 }
sub WARNING  { 1 }
sub CRITICAL { 2 }
sub UNKNOWN  { 3 }

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



sub run {
    my ( $self, $request ) = @_;

    if ( $request->{command} eq '__list_check_methods' ) {
        return {
            name   => $request->{command},
            status => 0,
            stdout => [ keys %{ $self->{available_checks} } ],
        };
    }

    # We return the payload without 'status' if we can't find this
    # check in our available checks.
    if ( !exists $self->{available_checks}{ $request->{command} } ) {
        return { 
            name   => $request->{command},
            status => UNKNOWN(),
            error  => $CHECK_DOES_NOT_EXIST_ERROR,
        };
    }

    my $command = $self->{available_checks}{ $request->{command} };
    return $command->( $request->{arguments} );
}



sub start {
    my ( $self ) = @_;

    $self->info( "Listening on %s", $self->{socket_path} );

    my $handler = tcp_server "unix/", $self->{socket_path}, sub {
        my ( $fh ) = @_;

        Dumper($fh);

        chomp( my $request_json = <$fh> );

        $self->debug( $request_json );

        my $request = GoDutch::JSON::from_json( $request_json );

        my $response = $self->run( $request );

        my $response_json = GoDutch::JSON::to_json( $response );

        $self->debug( $response_json );

        print $fh $response_json;
    };

    AE::cv->recv;
}



1; # End of GoDutch
