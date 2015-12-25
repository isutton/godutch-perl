package Basic;

sub checks {
    return {
        check01 => sub {
            return {
                name   => 'check01',
                status => 0,
                stdout => [],
            };
        },
    };
}

1;
