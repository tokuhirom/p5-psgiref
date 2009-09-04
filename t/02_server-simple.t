use strict;
use warnings;
use Test::More;
use HTTP::Request;
use HTTP::Headers::Fast;
use HTTP::Request::Common;
use PSGIRef;
use PSGIRef::Request;
use PSGIRef::Response;
use PSGIRef::Interface::ServerSimple;
use Test::TCP;
use LWP::UserAgent;
use PSGIRef::Test;

for my $i (0..PSGIRef::Test->count()-1) {
    run_one($i);
}
done_testing();
exit;

sub run_one {
    my $i = shift;
    my ($name, $reqgen, $handler, $test) = PSGIRef::Test->get_test($i);
    note $name;

    test_tcp(
        client => sub {
            my $port = shift;

            my $ua = LWP::UserAgent->new();
            my $res = $ua->request($reqgen->($port));
            $test->($res);
        },
        server => sub {
            my $port = shift;

            my $server = PSGIRef::Interface::ServerSimple->new(port => $port, address => '127.0.0.1');
            $server->run($handler);
        },
    );
}


