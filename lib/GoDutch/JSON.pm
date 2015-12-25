package GoDutch::JSON;

use strict;
use warnings;

use JSON ();

sub to_json ($@) {
    my ( $value, @options ) = @_;
    return JSON::to_json( $value, @options ) . "\n" ;
}

sub from_json ($@) {
    my ( $value, @options) = @_;
    return JSON::from_json( $value, @options );
}

1;
